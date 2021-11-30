import XCTest

import AsyncHTTPTests

var tests = [XCTestCaseEntry]()
tests += AsyncHTTPTests.allTests()
XCTMain(tests)
