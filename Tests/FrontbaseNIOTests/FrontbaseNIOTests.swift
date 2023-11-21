@testable import FrontbaseNIO
import NIO
import XCTest
import MemoryTools

class FrontbaseNIOTests: XCTestCase {

    func testVersion() throws {
        let conn = try FrontbaseConnection.makeFilebasedTest(); defer { conn.destroyTest() }
        
        let res = try conn.query ("VALUES server_name;").wait()
        print (res)
    }

    func testTables() throws {
        let conn = try FrontbaseConnection.makeFilebasedTest(); defer { conn.destroyTest() }
        _ = try conn.query ("CREATE TABLE foo (bar INT, baz VARCHAR(16), biz FLOAT)").wait()
        _ = try conn.query ("INSERT INTO foo VALUES (42, 'Life', 0.44)").wait()
        _ = try conn.query ("INSERT INTO foo VALUES (1337, 'Elite', 209.234)").wait()
        _ = try conn.query ("INSERT INTO foo VALUES (9, NULL, 34.567)").wait()

        if let resultBar = try conn.query ("SELECT * FROM foo WHERE bar = 42").wait().first {
            XCTAssertEqual (resultBar.firstValue (forColumn: "bar"), .integer (42))
            XCTAssertEqual (resultBar.firstValue (forColumn: "baz"), .text ("Life"))
            XCTAssertEqual (resultBar.firstValue (forColumn: "biz"), .float (0.44))
        } else {
            XCTFail ("Could not get bar result")
        }

        if let resultBaz = try conn.query ("SELECT * FROM foo where baz = 'Elite'").wait().first {
            XCTAssertEqual (resultBaz.firstValue (forColumn: "bar"), .integer (1_337))
            XCTAssertEqual (resultBaz.firstValue (forColumn: "baz"), .text ("Elite"))
        } else {
            XCTFail ("Could not get baz result")
        }

        if let resultBaz = try conn.query ("SELECT * FROM foo where bar = 9").wait().first {
            XCTAssertEqual (resultBaz.firstValue (forColumn: "bar"), .integer (9))
            XCTAssertEqual (resultBaz.firstValue (forColumn: "baz"), .null)
        } else {
            XCTFail("Could not get null result")
        }
    }

    func testUnicode() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        /// This string includes characters from most Unicode categories
        /// such as Latin, Latin-Extended-A/B, Cyrrilic, Greek etc.
        let unicode = "®¿ÐØ×ĞƋƢǂǊǕǮȐȘȢȱȵẀˍΔῴЖ♆"
        _ = try database.query ("CREATE TABLE \"foo\" (bar CHARACTER VARYING (1000))").wait()

        _ = try database.query ("INSERT INTO \"foo\" VALUES(?)", [unicode.frontbaseData!]).wait()
        let selectAllResults = try database.query ("SELECT * FROM \"foo\"").wait().first
        XCTAssertNotNil (selectAllResults)
        XCTAssertEqual (selectAllResults!.firstValue (forColumn: "bar"), .text (unicode))

        let selectWhereResults = try database.query ("SELECT * FROM \"foo\" WHERE bar = '\(unicode)'").wait().first
        XCTAssertNotNil (selectWhereResults)
        XCTAssertEqual (selectWhereResults!.firstValue (forColumn: "bar"), .text (unicode))
    }

    func testTinyInts() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let max = Int8.max

        _ = try database.query ("CREATE TABLE foo (\"max\" TINYINT)").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?)", [max.frontbaseData!]).wait()

        if let result = try! database.query ("SELECT * FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "max"), FrontbaseData.integer (Int64 (max)))
        }
    }

    func testSmallInts() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let max = Int16.max

        _ = try database.query ("CREATE TABLE foo (\"max\" SMALLINT)").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?)", [max.frontbaseData!]).wait()

        if let result = try! database.query ("SELECT * FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "max"), FrontbaseData.integer (Int64 (max)))
        }
    }

    func testInts() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let max = Int32.max

        _ = try database.query ("CREATE TABLE foo (\"max\" INTEGER)").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?)", [max.frontbaseData!]).wait()

        if let result = try! database.query ("SELECT * FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "max"), FrontbaseData.integer (Int64 (max)))
        }
    }

    func testLongInts() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let max = Int64.max

        _ = try database.query ("CREATE TABLE foo (\"max\" LONGINT)").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?)", [max.frontbaseData!]).wait()

        if let result = try! database.query ("SELECT * FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "max"), FrontbaseData.integer (max))
        }
    }

    func testDecimals() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let max: Decimal = 42000000.0
        let min: Decimal = 1.23

        _ = try database.query ("CREATE TABLE foo (\"max\" DECIMAL, \"min\" DECIMAL (30, 3))").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?, ?)", [max.frontbaseData!, min.frontbaseData!]).wait()

        if let result = try! database.query ("SELECT * FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "max"), FrontbaseData.decimal (max))
            XCTAssertEqual (result.firstValue (forColumn: "min"), FrontbaseData.decimal (min))
        }

        let decimal: Decimal = 42.0
        let frontbaseData = decimal.frontbaseData!
        XCTAssertEqual (Double (frontbaseData: frontbaseData), 42.0)
        XCTAssertEqual (Int (frontbaseData: frontbaseData), 42)
    }

    func testNumerics() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let max = 42000000.0
        let min = 1.23
        
        _ = try database.query ("CREATE TABLE foo (\"max\" NUMERIC, \"min\" NUMERIC (10, 3))").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?, ?)", [max.frontbaseData!, min.frontbaseData!]).wait()
        
        if let result = try! database.query ("SELECT * FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "max"), FrontbaseData.float (max))
            XCTAssertEqual (result.firstValue (forColumn: "min"), FrontbaseData.float (min))
        }
    }

    func testFloats() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let max = 42000000.0
        let min = 1.23
        
        _ = try database.query ("CREATE TABLE foo (\"max\" FLOAT, \"min\" FLOAT)").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?, ?)", [max.frontbaseData!, min.frontbaseData!]).wait()
        
        if let result = try! database.query ("SELECT * FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "max"), FrontbaseData.float (max))
            XCTAssertEqual (result.firstValue (forColumn: "min"), FrontbaseData.float (min))
        }
    }

    func testReals() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let max = 42000000.0
        let min = 1.23
        
        _ = try database.query ("CREATE TABLE foo (\"max\" REAL, \"min\" REAL)").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?, ?)", [max.frontbaseData!, min.frontbaseData!]).wait()
        
        if let result = try! database.query ("SELECT * FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "max"), FrontbaseData.float (max))
            XCTAssertEqual (result.firstValue (forColumn: "min"), FrontbaseData.float (min))
        }
    }

    func testDoubles() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let max = 42000000.0
        let min = 1.23
        
        _ = try database.query ("CREATE TABLE foo (\"max\" DOUBLE PRECISION, \"min\" DOUBLE PRECISION)").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?, ?)", [max.frontbaseData!, min.frontbaseData!]).wait()
        
        if let result = try! database.query ("SELECT * FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "max"), FrontbaseData.float (max))
            XCTAssertEqual (result.firstValue (forColumn: "min"), FrontbaseData.float (min))
        }
    }

    func testCharacters() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let string = "The lazy dog jumps of over the quick fox"
        
        _ = try database.query ("CREATE TABLE foo (\"string\" CHARACTER (100))").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?)", [string.frontbaseData!]).wait()
        
        if let result = try! database.query ("SELECT * FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "string"), FrontbaseData.text (string))
        }
    }

    func testBooleans() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let value = true
        
        _ = try database.query ("CREATE TABLE foo (\"value\" BOOLEAN)").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?)", [value.frontbaseData!]).wait()
        
        if let result = try! database.query ("SELECT * FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "value"), FrontbaseData.boolean (value))
        }
    }

    func testBlobs() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let data = Data ([0, 1, 2])

        _ = try database.query ("CREATE TABLE foo (bar BLOB)").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?)", [data.frontbaseData!]).wait()

        if let result = try database.query ("SELECT * FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "bar")?.blobData, data)
        } else {
            XCTFail()
        }
    }

    func testTimestamps() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let timestamp = Date()

        _ = try database.query ("CREATE TABLE foo (bar TIMESTAMP, baz TIMESTAMP (0), baw TIMESTAMP (3))").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?, ?, ?)", [timestamp.frontbaseData!, timestamp.frontbaseData!, timestamp.frontbaseData!]).wait()

        if let result = try database.query ("SELECT * FROM foo").wait().first {
            XCTAssert (abs ((result.firstValue (forColumn: "bar")?.timestampDate?.timeIntervalSinceReferenceDate ?? Double.infinity) - timestamp.timeIntervalSinceReferenceDate) < 0.001)
            XCTAssert (abs ((result.firstValue (forColumn: "baz")?.timestampDate?.timeIntervalSinceReferenceDate ?? Double.infinity) - timestamp.timeIntervalSinceReferenceDate) < 1)
            XCTAssert (abs ((result.firstValue (forColumn: "baw")?.timestampDate?.timeIntervalSinceReferenceDate ?? Double.infinity) - timestamp.timeIntervalSinceReferenceDate) < 0.001)
        } else {
            XCTFail()
        }
    }

    func testTimeZones() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let timestamp = Date()

        _ = try database.query ("CREATE TABLE foo (bar TIMESTAMP)").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?)", [ timestamp.frontbaseData! ]).wait()

        if let result = try database.query ("SELECT * FROM foo").wait().first {
            XCTAssert (abs ((result.firstValue (forColumn: "bar")?.timestampDate?.timeIntervalSinceReferenceDate ?? Double.infinity) - timestamp.timeIntervalSinceReferenceDate) < 0.001)
        } else {
            XCTFail()
        }
    }

    func testBits() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let bits: [UInt8] = [0, 1, 2, 3, 4, 5, 6, 7, 124, 125, 126, 127]
        let bitz: [UInt8] = [0x94, 0x71, 0xF1, 0xD9, 0x24, 0x59, 0xD6, 0x51, 0x56, 0x15]

        _ = try database.query ("CREATE TABLE foo (bar BIT (96), baz BIT VARYING (80))").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?, ?)", [ bits.frontbaseData!, bitz.frontbaseData! ]).wait()

        if let result = try database.query ("SELECT * FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "bar"), FrontbaseData.bits (bits))
            XCTAssertEqual (result.firstValue (forColumn: "baz"), FrontbaseData.bits (bitz))
        } else {
            XCTFail()
        }
    }

    func testBit96() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let bits = Bit96 (bits: (0, 1, 2, 3, 4, 5, 6, 7, 124, 125, 126, 127))
        let bitz = Bit96 (bits: (0x94, 0x71, 0xF1, 0xD9, 0x24, 0x59, 0xD6, 0x51, 0x56, 0x15, 0x83, 0x1E))
        
        _ = try database.query ("CREATE TABLE foo (bar BIT (96), baz BIT (96))").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?, ?)", [ bits.frontbaseData!, bitz.frontbaseData!]).wait()
        
        if let result = try database.query ("SELECT * FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "bar"), FrontbaseData.bits ([UInt8] (bits)))
            XCTAssertEqual (result.firstValue (forColumn: "baz"), FrontbaseData.bits ([UInt8] (bitz)))
        } else {
            XCTFail()
        }
    }

    func testIntervals() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let interval = TimeInterval (900.0)
        let start = Date()
        let end = start.addingTimeInterval (interval)
        
        _ = try database.query ("CREATE TABLE foo (\"start\" TIMESTAMP, \"end\" TIMESTAMP)").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?, ?)", [ start.frontbaseData!, end.frontbaseData!]).wait()
        
        if let result = try! database.query ("SELECT \"end\" - \"start\" AS \"timespan\" FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "timespan"), FrontbaseData.float (interval))
        }
    }

    func testError() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        do {
            _ = try database.query ("asdf").wait()
            XCTFail ("Should have errored")
        } catch let error as FrontbaseError {
            print (error)
            XCTAssert (error.message.contains("Syntax error"))
        } catch {
            XCTFail ("wrong error")
        }
    }

    func testDecodeSameColumnName() throws {
        let row = FrontbaseRow (data: [
            FrontbaseColumn (table: "foo", name: "id"): .text("foo"),
            FrontbaseColumn (table: "bar", name: "id"): .text("bar"),
        ])
        struct User: Decodable {
            var id: String
        }
        XCTAssertEqual (row.firstValue (forColumn: "id", inTable: "foo"), .text ("foo"))
        XCTAssertEqual (row.firstValue (forColumn: "id", inTable: "bar"), .text ("bar"))
    }

    func testMultiThreading() throws {
        let db = try FrontbaseConnection.makeNetworkedDatabase(); defer { db.destroyTest() }
        let elg = MultiThreadedEventLoopGroup (numberOfThreads: 2)
        let a = elg.next()
        let b = elg.next()
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async {
            let conn = try! db.newConnection (on: a)
            for i in 0 ..< 100 {
                print ("a \(i)")
                let res = try! conn.query("VALUES (1 + 1);").wait()
                print (res)
            }
            let _ = conn.close()
            group.leave()
        }
        group.enter()
        DispatchQueue.global().async {
            let conn = try! db.newConnection (on: b)
            for i in 0 ..< 100 {
                print ("b \(i)")
                let res = try! conn.query("VALUES (1 + 1);").wait()
                print (res)
            }
            let _ = conn.close()
            group.leave()
        }
        group.wait()
    }

    func testSingleThreading() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let string1 = "The lazy dog jumps of over the quick fox"
        let string2 = "Mauris ac est et nulla luctus vehicula sit amet vel justo"

        _ = try database.query ("CREATE TABLE foo (\"string\" CHARACTER (100))").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?)", [ string1.frontbaseData! ]).wait()
        _ = try database.query ("CREATE TABLE bar (\"string\" CHARACTER (100))").wait()
        _ = try database.query ("INSERT INTO bar VALUES (?)", [ string2.frontbaseData! ]).wait()

        let (foo, bar) = try! database.query ("SELECT * FROM foo")
            .and (database.query ("SELECT * FROM bar"))
            .wait()
        XCTAssertEqual (foo.first!.firstValue (forColumn: "string"), FrontbaseData.text (string1))
        XCTAssertEqual (bar.first!.firstValue (forColumn: "string"), FrontbaseData.text (string2))
    }

    func testAnyType() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let values: [FrontbaseDataConvertible] = [
            true,
            37,
            Decimal (string: "3.1415926535898")!,
            Decimal (string: "12906.40372")!,
            "Kilroy was here!",
            Date (timeIntervalSinceReferenceDate: 1_000_000_000)
        ]

        _ = try database.query ("CREATE TABLE foo (bar ANY TYPE)").wait()
        for value in values {
            _ = try database.query ("INSERT INTO foo VALUES (?)", [ value.frontbaseData! ]).wait()
        }

        let results: [FrontbaseRow] = try database.query ("SELECT index, bar FROM foo ORDER BY 1").wait()
        var index = 0
        for result in results {
            XCTAssertEqual (result.firstValue (forColumn: "bar"), values[index].frontbaseData!)
            index += 1
        }
    }

    func testTransactions() throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }
        let string = "Lorem ipsum set dolor mit amet"

        _ = try database.query ("CREATE TABLE foo (\"string\" CHARACTER (100))").wait()

        _ = try database.query ("INSERT INTO foo VALUES (?)", [ string.frontbaseData! ]).wait()
        _ = try database.query ("ROLLBACK").wait()
        if let result = try! database.query ("SELECT COUNT (*) AS counter, MIN (string) AS value FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "counter"), FrontbaseData.decimal (1.0))
            XCTAssertEqual (result.firstValue (forColumn: "value"), FrontbaseData.text (string))
        }

        database.autoCommit = false
        _ = try database.query ("INSERT INTO foo VALUES (?)", ["Sed euismod lacus a magna aliquam".frontbaseData! ]).wait()
        _ = try database.query ("ROLLBACK").wait()
        if let result = try! database.query ("SELECT COUNT (*) AS counter, MIN (string) AS value FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "counter"), FrontbaseData.decimal (1.0))
            XCTAssertEqual (result.firstValue (forColumn: "value"), FrontbaseData.text (string))
        }
        _ = try database.query ("INSERT INTO foo VALUES (?)", [ "Donec eget sollicitudin odio".frontbaseData! ]).wait()
        _ = try database.query ("COMMIT").wait()
        if let result = try! database.query ("SELECT COUNT (*) AS counter, MIN (string) AS value FROM foo").wait().first {
            XCTAssertEqual (result.firstValue (forColumn: "counter"), FrontbaseData.decimal (2.0))
            XCTAssertEqual (result.firstValue (forColumn: "value"), FrontbaseData.text ("Donec eget sollicitudin odio"))
        }
    }

#if compiler(>=5.5) && canImport(_Concurrency)
@available (macOS 12, iOS 15, *)
    func testTransactionsAsync() async throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }

        _ = try await database.query ("CREATE TABLE foo (\"string\" CHARACTER (100))").get()

        _ = try await database.query ("INSERT INTO foo VALUES (?)", [ "Curabitur suscipit non ante sed auctor".frontbaseData! ]).get()
        _ = try await database.query ("ROLLBACK").get()
        if let result = try await database.query ("SELECT COUNT (*) AS counter, MIN (string) AS value FROM foo").get().first {
            XCTAssertEqual (result.firstValue (forColumn: "counter"), FrontbaseData.decimal (1.0))
            XCTAssertEqual (result.firstValue (forColumn: "value"), FrontbaseData.text ("Curabitur suscipit non ante sed auctor"))
        }

        database.autoCommit = false
        _ = try await database.query ("INSERT INTO foo VALUES (?)", ["Donec eget sollicitudin odio".frontbaseData! ]).get()
        _ = try await database.query ("ROLLBACK").get()
        if let result = try await database.query ("SELECT COUNT (*) AS counter, MAX (string) AS value FROM foo").get().first {
            XCTAssertEqual (result.firstValue (forColumn: "counter"), FrontbaseData.decimal (1.0))
            XCTAssertEqual (result.firstValue (forColumn: "value"), FrontbaseData.text ("Curabitur suscipit non ante sed auctor"))
        }
        _ = try await database.query ("INSERT INTO foo VALUES (?)", [ "Lorem ipsum set dolor mit amet".frontbaseData! ]).get()
        _ = try await database.query ("COMMIT").get()
        if let result = try await database.query ("SELECT COUNT (*) AS counter, MAX (string) AS value FROM foo").get().first {
            XCTAssertEqual (result.firstValue (forColumn: "counter"), FrontbaseData.decimal (2.0))
            XCTAssertEqual (result.firstValue (forColumn: "value"), FrontbaseData.text ("Lorem ipsum set dolor mit amet"))
        }
        database.autoCommit = true

        try await database.withTransaction { connection in
            _ = try await connection.query ("INSERT INTO foo VALUES (?)", ["Pellentesque habitant morbi tristique senectus et netus".frontbaseData! ]).get()
            if let result = try await database.query ("SELECT COUNT (*) AS counter, MAX (string) AS value FROM foo").get().first {
                XCTAssertEqual (result.firstValue (forColumn: "counter"), FrontbaseData.decimal (3.0))
                XCTAssertEqual (result.firstValue (forColumn: "value"), FrontbaseData.text ("Pellentesque habitant morbi tristique senectus et netus"))
            }
        }

        try await database.withTransaction { connection in
            _ = try await connection.query ("INSERT INTO foo VALUES (?)", ["Sed euismod lacus a magna aliquam".frontbaseData! ]).get()
            if let result = try await database.query ("SELECT COUNT (*) AS counter, MAX (string) AS value FROM foo").get().first {
                XCTAssertEqual (result.firstValue (forColumn: "counter"), FrontbaseData.decimal (4.0))
                XCTAssertEqual (result.firstValue (forColumn: "value"), FrontbaseData.text ("Sed euismod lacus a magna aliquam"))
            }
        }
    }
#endif

#if compiler(>=5.5) && canImport(_Concurrency)
@available (macOS 12, iOS 15, *)
    func testCommand() async throws {
        let database = try FrontbaseConnection.makeFilebasedTest(); defer { database.destroyTest() }

        _ = try await database.query ("CREATE TABLE foo (\"string\" CHARACTER (100))").get()

        if let result = try await database.command ("EXTRACT TABLE foo") {
            XCTAssertEqual (result, #"{COLUMNS = ({ NAME = "string"; CODE = 9; DATATYPE = CHARACTER; WIDTH = 100; NORMALIZE = NO; PRIVS = (SELECT, INSERT, UPDATE, REFERENCES); }); PRIVS = (SELECT, INSERT, UPDATE, DELETE, REFERENCES); CATALOG = "DATABASE"; SCHEMA = "_SYSTEM"; TABLE = "foo"; "TABLE DISK ZONE" = "SYSTEM"; "VARYING DISK ZONE" = "SYSTEM"; "INDEX DISK ZONE" = "SYSTEM"; "LOB DISK ZONE" = "SYSTEM"; "INDEX MODE" = "PRESERVE TIME"; ROW_COUNT = 0; "LOOK SEE" = (  ); }"#)
        }
    }
#endif

    func testAllocation() throws {
        let database = try FrontbaseConnection.makeFilebasedTest();
        let before = getMemoryUsed()
        let string = "Lorem ipsum set dolor mit amet"

        _ = try database.query ("CREATE TABLE foo (\"string\" CHARACTER (100))").wait()
        _ = try database.query ("INSERT INTO foo VALUES (?)", [ string.frontbaseData! ]).wait()
        _ = try database.query ("COMMIT").wait()

        for _ in 1...10000 {
            if let result = try! database.query ("SELECT COUNT (*) AS counter, MIN (string) AS value FROM foo").wait().first {
                XCTAssertEqual (result.firstValue (forColumn: "counter"), FrontbaseData.decimal (1.0))
                XCTAssertEqual (result.firstValue (forColumn: "value"), FrontbaseData.text (string))
            }
        }
        database.destroyTest()
        let after = getMemoryUsed()
        let used = after > before ? after - before : 0

        XCTAssertLessThan (used, 500000)
    }
}
