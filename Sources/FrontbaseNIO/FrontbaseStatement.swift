import CFrontbaseSupport

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

    private static func parse (sql: String) -> [FrontbaseStatementNode] {
        var nodes = [FrontbaseStatementNode]()
        var inQuotedString = false
        var inQuotedName = false
        var index = sql.startIndex
        var character: Character
        var previousStart = index
        var previousCharacter: Character?

        while index < sql.endIndex {
            character = sql[index]
            switch character {
                case "'":
                    if inQuotedString && (previousCharacter != "'") {
                        inQuotedString = false
                    } else if !inQuotedName {
                        inQuotedString = true
                    }

                case "\"":
                    inQuotedName = !inQuotedName

                case "?":
                    if !inQuotedString && !inQuotedName {
                        if previousStart < index {
                            nodes.append (.text (sql[previousStart ..< index]))
                            previousStart = sql.index (after: index)
                        }
                        nodes.append (.placeholder)
                    }

                default:
                    break
            }

            previousCharacter = character
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
        guard connection.databaseConnection != nil else {
            throw FrontbaseError (reason: .error, message: "Connection has been closed")
        }
        var errorMessage: UnsafePointer<Int8>? = nil
        let resultSet: FBSResult? = withUnsafeMutablePointer (to: &errorMessage) { errorMessagePointer in
            return fbsExecuteSQL (connection.databaseConnection, sql + ";", connection.autoCommit, errorMessagePointer)
        }

        if let message = errorMessage {
            throw FrontbaseError (reason: .error, message: String (cString: message))
        }

        self.resultSet = resultSet
    }

    internal func nextRow() throws -> FrontbaseRow? {
        if let row = fbsFetchRow (resultSet) {
            let count = fbsGetColumnCount (resultSet)
            var columnData: [FrontbaseColumn: FrontbaseData] = [:]

            for columnIndex in 0 ..< count {
                let info: FBSColumnInfo = fbsGetColumnInfoAtIndex (resultSet, columnIndex)
                let tableName = String (cString: info.tableName)
                let labelName = String (cString: info.labelName)
                let column = FrontbaseColumn (table: tableName == "_NA" ? nil : tableName, name: labelName)

                columnData[column] = try FrontbaseData.retrieve (from: row, at: columnIndex, type: info.datatype, statement: self)
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

    // MARK: Private
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
}
