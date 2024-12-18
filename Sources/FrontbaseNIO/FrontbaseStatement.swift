import CFrontbaseSupport
import Foundation

internal class FrontbaseStatement {
    internal let connection: FrontbaseConnection
    internal let nodes: [FrontbaseStatementNode]
    internal var sql: String?
    internal var resultSet: FBSResult?

    internal init(query: String, on connection: FrontbaseConnection) throws {
        self.connection = connection
        self.nodes = FrontbaseStatement.parse (sql: query)
    }

    deinit {
        if let result = resultSet {
            fbsCloseResult (result)
        }
    }

    enum ParseState {
        case text
        case beginningOfQuotedString
        case quotedString
        case possibleEndOfQuotedString
        case quotedName
    }
    private static func parse (sql: String) -> [FrontbaseStatementNode] {
        var nodes = [FrontbaseStatementNode]()
        var state = ParseState.text
        var index = sql.startIndex
        var character: Character
        var previousStart = index

        while index < sql.endIndex {
            character = sql[index]
            switch state {
                case .text:
                    if character == "'" {
                        state = .beginningOfQuotedString
                    } else if character == "\"" {
                        state = .quotedName
                    } else if character == "?" {
                        if previousStart < index {
                            nodes.append (.text (sql[previousStart ..< index]))
                            previousStart = sql.index (after: index)
                        }
                        nodes.append (.placeholder)
                    }

                case .beginningOfQuotedString:
                    if character == "'" {
                        state = .possibleEndOfQuotedString
                    } else {
                        state = .quotedString
                    }

                case .quotedString:
                    if character == "'" {
                        state = .possibleEndOfQuotedString
                    }

                case .possibleEndOfQuotedString:
                    if character == "'" {
                        state = .quotedString
                    } else {
                        state = .text
                    }

                case .quotedName:
                    if character == "\"" {
                        state = .text
                    }
            }

            index = sql.index (after: index)
        }

        if previousStart < sql.endIndex {
            nodes.append (.text (sql[previousStart ..< sql.endIndex]))
        }

        return nodes
    }

    internal func bind (_ binds: [FrontbaseData]) throws {
        var stack = binds
        var result = ""

        for node in nodes {
            switch node {
                case .text (let text):
                    result += text

                case .placeholder:
                    guard !stack.isEmpty else {
                        throw ParseError.invalidNumberOfParameters
                    }
                    result += stack.removeFirst().sql (connection: self.connection)
            }
        }

        if !stack.isEmpty {
            throw ParseError.invalidNumberOfParameters
        }

        self.sql = result
    }

    internal func executeQuery() throws {
        guard let sql = self.sql else {
            throw ParseError.noStatement
        }
        guard let databaseConnection = connection.databaseConnection, fbsConnectionIsOpen (databaseConnection) else {
            throw FrontbaseError (reason: .error, message: "Connection has been closed")
        }
        var errorMessage: UnsafeMutablePointer<Int8>? = nil
        let resultSet: FBSResult? = fbsExecuteSQL (connection.databaseConnection!, sql + ";", connection.autoCommit, &errorMessage)

        if let message = errorMessage {
            defer { free(message); errorMessage = nil }
            throw FrontbaseError (reason: .error, message: String (cString: message))
        }

        self.resultSet = resultSet
    }

    internal func nextRow() throws -> FrontbaseRow? {
        if let resultSet,
           let row = fbsFetchRow (resultSet) {
            let count = fbsGetColumnCount (resultSet)
            var columnData: [FrontbaseColumn: FrontbaseData] = [:]

            for columnIndex in 0 ..< count {
                let info: FBSColumnInfo = fbsGetColumnInfoAtIndex (resultSet, columnIndex)
                let tableName = String (cString: info.tableName)
                let labelName = String (cString: info.labelName)
                let column = FrontbaseColumn (table: tableName == "_NA" ? nil : tableName, name: labelName)

                columnData[column] = try FrontbaseData.retrieve (from: row, at: columnIndex, columnInfo: info, statement: self, resultSet: resultSet)
            }

            fbsReleaseRow (row)

            return FrontbaseRow (data: columnData)
        } else {
            if let result = resultSet {
                fbsCloseResult (result)
                resultSet = nil
            }
            return nil
        }
    }

    internal func message() throws -> String? {
        if let message = fbsFetchMessage (resultSet) {
            return String (cString: message)
        } else {
            return nil
        }
    }

    internal func structure() throws -> [StructureColumn] {
        guard let resultSet else {
            return []
        }

        let count = fbsGetColumnCount (resultSet)
        var columns: [StructureColumn] = []

        for columnIndex in 0 ..< count {
            let info = fbsGetColumnInfoAtIndex (resultSet, columnIndex)
            let datatype: FrontbaseDataType

            switch info.datatype {
                case FBS_PrimaryKey:
                    datatype = .integer

                case FBS_Boolean:
                    datatype = .boolean

                case FBS_Integer:
                    datatype = .integer

                case FBS_SmallInteger:
                    datatype = .integer

                case FBS_Float:
                    datatype = .real

                case FBS_Real:
                    datatype = .real

                case FBS_Double:
                    datatype = .real

                case FBS_Numeric:
                    datatype = .real

                case FBS_Decimal:
                    datatype = .decimal

                case FBS_Character:
                    datatype = .text

                case FBS_VCharacter:
                    datatype = .text

                case FBS_Bit:
                    datatype = .bits

                case FBS_VBit:
                    datatype = .varyingbits

                case FBS_Date:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_Time:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_TimeTZ:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_Timestamp:
                    datatype = .timestamp

                case FBS_TimestampTZ:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_YearMonth:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_DayTime:
                    datatype = .real

                case FBS_CLOB:
                    datatype = .blob

                case FBS_BLOB:
                    datatype = .blob

                case FBS_TinyInteger:
                    datatype = .integer

                case FBS_LongInteger:
                    datatype = .integer

                case FBS_CircaDate:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_AnyType:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                default:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")
            }

            columns.append (StructureColumn (column: String (cString: info.labelName), type: datatype, isNullable: info.isNullable))
        }

        return columns
    }
}

internal enum FrontbaseStatementNode {
    case text (Substring)
    case placeholder

    var description: String {
        switch self {
            case .text (let text):
                return "\t\(text)"

            case .placeholder:
                return "\t?"
        }
    }
}

enum ParseError: Error {
    case invalidNumberOfParameters
    case noStatement
}

enum BlobError: Error {
    case createFailed
    case noConnection
}
