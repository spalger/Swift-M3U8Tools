//
//  Test.swift
//  M3U8Tools
//
//  Created by Spencer Alger on 8/28/24.
//

@testable import M3U8Tools
import Testing

struct StringParserTests {
  @Test func slurpCharacterSet() {
    let p = Parser("ABCdefg")

    #expect(p.slurp(.upperCase) == "ABC")
    #expect(p.char == "d")
    #expect(p.slurp(.whitespace) == "")
    #expect(p.slurp(.number) == "")
    #expect(p.slurp(.alphaNumeric) == "defg")
    #expect(p.slurp(.letter) == "")
  }

  @Test func isAtEnd() {
    #expect(Parser("").isAtEnd)

    let a = Parser("abc")
    a.skip(.alphaNumeric)
    #expect(a.isAtEnd)

    let b = Parser("abc")
    b.skip(.whitespace)
    #expect(!b.isAtEnd)
  }

  @Test func char() {
    let p = Parser("ABCdefg")

    #expect(p.char == "A")
    p.skip(1)
    #expect(p.char == "B")
    p.skip(1)
    #expect(p.char == "C")
    p.skip(1)
    #expect(p.char == "d")
    p.skip(1)
    #expect(p.char == "e")
    p.skip(1)
    #expect(p.char == "f")
    p.skip(1)
    #expect(p.char == "g")
    p.skip(1)
    #expect(p.char == nil)
    #expect(p.isAtEnd)
  }

  @Test func peek() {
    let p = Parser("ABC")

    #expect(p.char == "A")
    #expect(p.peek == "B")
    p.skip(1)
    #expect(p.char == "B")
    #expect(p.peek == "C")
    p.skip(1)
    #expect(p.char == "C")
    #expect(p.peek == nil)
  }

  @Test func skip() throws {
    let p = Parser("   ABC123youandme")
    #expect(p.char == " ")

    p.skip(.whitespace)
    #expect(p.char == "A")

    p.skip(2)
    #expect(p.char == "C")

    try p.skip(control: "C")
    #expect(p.char == "1")

    p.skip(.number)
    #expect(p.char == "y")

    p.skip(.alphaNumeric, max: 3)
    #expect(p.char == "a")
  }

  @Test func upcoming() throws {
    let p = Parser("foobarbaz")
    #expect(p.upcoming("z"))

    _ = p.rest()
    #expect(p.upcoming("z") == false)

    let p2 = Parser("one\ntwo\nthree")
    #expect(p2.upcoming("\n"))
    _ = try p2.slurpLine()
    #expect(p2.upcoming("\n"))
    _ = try p2.slurpLine()
    #expect(p2.upcoming("\n") == false)
  }

  @Test func endLine() throws {
    let p = Parser("hello\nworld")

    do {
      try p.endLine()
      #expect(Bool(false))
    } catch {
      #expect(error == ParseError.expectedEndOfLine(at: 0))
    }

    p.skip(.alphaNumeric)
    try p.endLine()

    p.skip(.alphaNumeric)
    // end line should return at the end of the string, rather than throwing unexpectedEndOfString
    try p.endLine()
  }

  @Test func slurpLine() throws {
    let p = Parser("a\nbbb\nc\n\n\n1234")
    #expect(try p.slurpLine() == "a")
    #expect(try p.slurpLine() == "bbb")
    #expect(try p.slurpLine() == "c")
    #expect(try p.slurpLine() == "")
    #expect(try p.slurpLine() == "")
    // final line has no terminator, but it works and is returned, leaving the parser at the end of the input
    #expect(try p.slurpLine() == "1234")

    do {
      _ = try p.slurpLine()
      #expect(Bool(false))
    } catch {
      #expect(error == ParseError.unexpectedEndOfString(at: nil, expected: "\n"))
    }
  }

  @Test func slurp() {
    let p = Parser("aaaaa123.45bflkj1.2")
    #expect(p.slurp(.lowerCase) == "aaaaa")
    #expect(p.slurp(.float) == "123.45")
    #expect(p.slurp(.alphaNumeric) == "bflkj1")
    p.skip(1)
    #expect(p.slurp(.number) == "2")
    #expect(p.isAtEnd)
  }

  @Test func slurpUntil() throws {
    let p = Parser("A^2:b-cxC\\\"CC\"&d")
    #expect(try p.slurpUntil(.colon) == "A^2")
    // escaped quote is included in the output and does not count as the control quote, backslash for escaping is dropped
    #expect(try p.slurpUntil(.quote) == "b-cxC\"CC")
    #expect(p.rest() == "&d")

    let p2 = Parser("abcdefg")
    #expect(try p2.slurpUntil(.equal, required: false) == "abcdefg")

    let p3 = Parser("abc\ndefg")
    #expect(try p3.slurpUntil(.equal, required: false) == "abc")
    try p3.endLine()
    #expect(try p3.slurpUntil(.equal, required: false) == "defg")

    do {
      _ = try Parser("abcdefg").slurpUntil(.equal, required: true)
      #expect(Bool(false))
    } catch {
      #expect(error == ParseError.unexpectedEndOfString(at: nil, expected: "="))
    }
  }

  @Test func slurpInt() throws {
    let p = Parser("key=1234")
    #expect(try p.slurpUntil(.equal) == "key")
    #expect(try p.slurpInt() == 1234)
    #expect(p.isAtEnd)

    do {
      _ = try Parser("foo").slurpInt()
      #expect(Bool(false))
    } catch {
      #expect(error == ParseError.invalidNumber(at: 0, ""))
    }
  }

  @Test func slurpDouble() throws {
    let p = Parser("key=1234.5678")
    #expect(try p.slurpUntil(.equal) == "key")
    #expect(try p.slurpDouble() == 1234.5678)
    #expect(p.isAtEnd)

    do {
      _ = try Parser("foo").slurpDouble()
      #expect(Bool(false))
    } catch {
      #expect(error == ParseError.invalidNumber(at: 0, ""))
    }
  }

  @Test func rest() {
    let p = Parser("abcdefg")
    #expect(p.rest() == "abcdefg")
    #expect(p.isAtEnd)
  }

  @Test func slurpAttributes() throws {
    // stops parsing attributes at the end of the content
    let p = Parser("key=value,key2=value2")
    #expect(try p.slurpAttributes() == [
      "key": "value",
      "key2": "value2"
    ])

    // stops parsing attributes at the end of the line
    let p2 = Parser("key=value,key2=value2\nabc")
    #expect(try p2.slurpAttributes() == [
      "key": "value",
      "key2": "value2"
    ])
    #expect(p2.rest() == "abc")
  }
}
