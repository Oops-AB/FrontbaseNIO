#if !canImport(ObjectiveC)
import XCTest

extension FrontbaseNIOTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__FrontbaseNIOTests = [
        ("testAllocation", testAllocation),
        ("testAnyType", testAnyType),
        ("testBit96", testBit96),
        ("testBits", testBits),
        ("testBlobs", testBlobs),
        ("testBooleans", testBooleans),
        ("testCharacters", testCharacters),
        ("testDecimals", testDecimals),
        ("testDecodeSameColumnName", testDecodeSameColumnName),
        ("testDoubles", testDoubles),
        ("testError", testError),
        ("testFloats", testFloats),
        ("testIntervals", testIntervals),
        ("testInts", testInts),
        ("testLongInts", testLongInts),
        ("testMultiThreading", testMultiThreading),
        ("testNumerics", testNumerics),
        ("testReals", testReals),
        ("testSingleThreading", testSingleThreading),
        ("testSmallInts", testSmallInts),
        ("testTables", testTables),
        ("testTimestamps", testTimestamps),
        ("testTimeZones", testTimeZones),
        ("testTinyInts", testTinyInts),
        ("testTransactions", testTransactions),
        ("testUnicode", testUnicode),
        ("testVersion", testVersion),
    ]
}

extension FrontbaseStatementTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__FrontbaseStatementTests = [
        ("testPlainStatement", testPlainStatement),
        ("testPlainStatementWithExtraParameters", testPlainStatementWithExtraParameters),
        ("testQuotedStringStatement", testQuotedStringStatement),
        ("testSingleIntegerStatement", testSingleIntegerStatement),
        ("testSingleIntegerStatementWithMissingParameter", testSingleIntegerStatementWithMissingParameter),
        ("testStringAndIntegerStatement", testStringAndIntegerStatement),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(FrontbaseNIOTests.__allTests__FrontbaseNIOTests),
        testCase(FrontbaseStatementTests.__allTests__FrontbaseStatementTests),
    ]
}
#endif