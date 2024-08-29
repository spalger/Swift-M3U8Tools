////
////  Test M3U8Token.swift
////  M3U8Tools
////
////  Created by Spencer Alger on 8/28/24.
////
//
// @testable import M3U8Tools
// import Testing
// import XCTest
//
// struct M3U8TokenTests {
//  @Test("Parses attribute strings of different complexities")
//  func testAttributeParsing() throws {
//    func test(_ input: String, _ expected: [String: String]) {
//      let attribute = try! Node.parseAttributes(input)
//      #expect(attribute == Node.attributes(expected))
//    }
//
//    test("foo=bar", ["foo": "bar"])
//    test("foo=\"bar baz\"", ["foo": "bar baz"])
//    test("foo=\"bar, baz\"", ["foo": "bar, baz"])
//    test("foo=bar,baz=\"1\\\"2\\\"34\"", ["foo": "bar", "baz": "1\"2\"34"])
//  }
//
//  @Test("Parses byteRanges")
//  func parseByteRanges() throws {
//    #expect(try! Node.parseByteRange("100.0@200.100") == .byteRange(length: 100.0, offset: 200.1))
//    #expect(try! Node.parseByteRange("100.0") == .byteRange(length: 100.0, offset: 0))
//
//    do {
//      _ = try Node.parseByteRange("100@")
//      #expect(Bool(false))
//    } catch {
//      #expect(error == ParseError.invalidNumber(""))
//    }
//
//    do {
//      _ = try Node.parseByteRange("100x")
//      #expect(Bool(false))
//    } catch {
//      #expect(error == ParseError.unexpectedCharacter("x", expected: "@"))
//    }
//
//    do {
//      _ = try Node.parseByteRange("x@y")
//      #expect(Bool(false))
//    } catch {
//      #expect(error == ParseError.invalidNumber(""))
//    }
//  }
// }
