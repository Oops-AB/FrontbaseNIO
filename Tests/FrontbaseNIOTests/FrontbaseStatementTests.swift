@testable import FrontbaseNIO
import XCTest

final class FrontbaseStatementTests: XCTestCase {
    func testPlainStatement() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let preparedStatement = try FrontbaseStatement (query: "SELECT a, b, c FROM t WHERE a = 2", on: database)
        try preparedStatement.bind ([])

        XCTAssertEqual (preparedStatement.sql, "SELECT a, b, c FROM t WHERE a = 2")
    }

    func testPlainStatementWithExtraParameters() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let preparedStatement = try FrontbaseStatement (query: "SELECT a, b, c FROM t WHERE a = 2", on: database)
        XCTAssertThrowsError(try preparedStatement.bind ([FrontbaseData.integer(1)]))
    }

    func testSingleIntegerStatement() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let preparedStatement = try FrontbaseStatement (query: "SELECT a, b, c FROM t WHERE a = ?", on: database)
        try preparedStatement.bind ([FrontbaseData.integer(7)])

        XCTAssertEqual (preparedStatement.sql, "SELECT a, b, c FROM t WHERE a = 7")
    }

    func testSingleIntegerStatementWithMissingParameter() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let preparedStatement = try FrontbaseStatement (query: "SELECT a, b, c FROM t WHERE a = ?", on: database)
        XCTAssertThrowsError (try preparedStatement.bind ([]))
    }

    func testStringAndIntegerStatement() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let preparedStatement = try FrontbaseStatement (query: "SELECT a, \"b\", c, ? FROM t WHERE a = ? AND b = 'What?' OR c = 'Strange''!'", on: database)
        try preparedStatement.bind ([FrontbaseData.text ("executive"), FrontbaseData.integer (7)])
        
        XCTAssertEqual (preparedStatement.sql, "SELECT a, \"b\", c, 'executive' FROM t WHERE a = 7 AND b = 'What?' OR c = 'Strange''!'")
    }

    func testQuotedStringStatement() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let preparedStatement = try FrontbaseStatement (query: "SELECT a, \"b\", c, ? FROM t WHERE a = ? AND b = 'What?' OR c = 'Strange''!'", on: database)
        try preparedStatement.bind ([FrontbaseData.text ("'; DROP TABLE bob;"), FrontbaseData.integer (7)])

        XCTAssertEqual (preparedStatement.sql, "SELECT a, \"b\", c, '''; DROP TABLE bob;' FROM t WHERE a = 7 AND b = 'What?' OR c = 'Strange''!'")
    }

    func testEmptyStringStatement() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let preparedStatement = try FrontbaseStatement (query: """
            update "bof_message_template_texts" set "text" = '' where "_pk" = x'deadbeefabcd000000000000';
            update "bof_message_template_texts" set "text" = 'Är du&nbsp;<b>pensionär</b>? Då ska du istället ladda upp&nbsp;<b>utbetalningsplan/beslut
        från Pensionsmyndigheten</b>');
        """, on: database)
        try preparedStatement.bind ([])

        XCTAssertEqual (preparedStatement.sql, """
            update "bof_message_template_texts" set "text" = '' where "_pk" = x'deadbeefabcd000000000000';
            update "bof_message_template_texts" set "text" = 'Är du&nbsp;<b>pensionär</b>? Då ska du istället ladda upp&nbsp;<b>utbetalningsplan/beslut
        från Pensionsmyndigheten</b>');
        """)
    }
}
