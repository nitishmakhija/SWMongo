import XCTest

import MongoKittenTests

var tests = [XCTestCaseEntry]()
tests += MongoKittenTests.allTests()
XCTMain(tests)
