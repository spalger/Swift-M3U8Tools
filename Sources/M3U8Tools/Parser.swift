//
//  Parser.swift
//  M3U8Tools
//
//  Created by Spencer Alger on 8/28/24.
//

import Foundation

class Parser {
  enum Symbol: Character {
    case equal = "="
    case comma = ","
    case colon = ":"
    case quote = "\""
  }

  enum CharacterType: String {
    case whitespace = " \t\r\n"
    case letter = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    case number = "0123456789"
    case float = "0123456789."
    case alphaNumeric = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    case upperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    case tagName = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-"
    case lowerCase = "abcdefghijklmnopqrstuvwxyz"
  }

  private(set) var pos: String.Index?
  var offset: Int? { pos?.utf16Offset(in: string) }

  var isAtEnd: Bool = false
  var char: Character?
  var eol: String?

  var string: String

  init(_ input: String) {
    self.string = input
    self.pos = string.startIndex == string.endIndex ? nil : string.startIndex
    step(0)
  }

  var isEol: Bool {
    return eol != nil
  }

  var peek: Character? {
    if let pos, string.distance(from: pos, to: string.endIndex) > 1 {
      return string[string.index(after: pos)]
    } else {
      return nil
    }
  }

  func skip(_ max: Int) {
    var count = 0
    while count < max, !isAtEnd {
      count += 1
      step()
    }
  }

  func skip(_ type: CharacterType, max: Int = Int.max) {
    var count = 0
    while count < max, let char, type.rawValue.contains(char) {
      count += 1
      step()
    }
  }

  func skip(_ control: Symbol) throws(ParseError) {
    try skip(control: control.rawValue)
  }

  func skip(control: Character) throws(ParseError) {
    if let char {
      if char != control {
        throw ParseError.unexpectedCharacter(at: offset, char, expected: control)
      }

      step()
      return
    }

    throw ParseError.unexpectedEndOfString(at: offset, expected: control)
  }

  func upcoming(_ type: Character) -> Bool {
    if let pos {
      return string.suffix(from: pos).firstIndex(of: type) != nil
    } else {
      return false
    }
  }

  func endLine() throws(ParseError) {
    if isAtEnd { return }

    if let eol {
      step(eol.count)
    } else {
      throw ParseError.expectedEndOfLine(at: offset)
    }
  }

  func slurpLine() throws(ParseError) -> String {
    if isAtEnd {
      throw ParseError.unexpectedEndOfString(at: offset, expected: "\n")
    }

    var result = ""
    while true {
      guard let char else { return result }

      if let eol {
        step(eol.count)
        return result
      }

      result.append(char)
      step()
      continue
    }
  }

  func slurp(_ type: CharacterType, max: Int = Int.max) -> String {
    var count = 0
    var result = ""

    while count < max, let char, type.rawValue.contains(char) {
      count += 1
      result.append(char)
      step()
    }

    return result
  }

  func slurpUntil(_ control: Symbol, required req: Bool = true) throws(ParseError) -> String {
    return try slurpUntil(control: control.rawValue, required: req)
  }

  func slurpUntil(control: Character, required: Bool = true) throws(ParseError) -> String {
    var result = ""
    while true {
      // if we iterate to the end of the line, stop slurping and either throw because we missed the control or return
      if eol != nil {
        if required {
          throw ParseError.unexpectedCharacter(at: offset, "\n", expected: control)
        } else {
          return result
        }
      }

      if let char {
        if char != control {
          // when we encounter an escaped character, copy over the following character regardless of what it is
          if char == "\\", let escaped = peek {
            result.append(escaped)
            step(2)
          } else {
            result.append(char)
            step()
          }
        } else {
          break
        }
      } else if required {
        throw ParseError.unexpectedEndOfString(at: offset, expected: control)
      } else {
        break
      }
    }

    // step over the control character
    step()
    return result
  }

  private func step(_ count: Int = 1) {
    if let pos {
      self.pos = string.index(pos, offsetBy: count, limitedBy: string.index(before: string.endIndex))
    } else {
      pos = nil
    }

    isAtEnd =
      pos == nil

    char =
      if let pos { string[pos] }
      else { nil }

    eol =
      if let char, char == "\n" { "\n" }
      else if let char, char == "\r", let peek, peek == "\n" { "\r\n" }
      else { nil }
  }
}

// MARK: Parsing helpers

extension Parser {
  func slurpInt() throws(ParseError) -> Int {
    let intStr = slurp(.number)

    guard let int = Int(intStr) else {
      throw ParseError.invalidNumber(at: offset, intStr)
    }

    return int
  }

  func slurpDouble() throws(ParseError) -> Double {
    let doubleStr = slurp(.float)

    guard let double = Double(doubleStr) else {
      throw ParseError.invalidNumber(at: offset, doubleStr)
    }

    return double
  }

  func rest() -> String {
    guard let pos else { return "" }
    step(Int.max)
    return String(string.suffix(from: pos))
  }

  func slurpAttributes() throws(ParseError) -> [Ast.Node.Attribute] {
    var attrs = [Ast.Node.Attribute]()

    while true {
      if let eol {
        skip(eol.count)
        break
      }

      if isAtEnd {
        break
      }

      let key = try slurpUntil(.equal)

      // if the value starts with a quote, parse the whole value as a quoted string
      if char == "\"" {
        try skip(.quote)
        try attrs.append(.init(key, .quoted(slurpUntil(.quote))))
        if char == "," { skip(1) }
      } else {
        try attrs.append(.init(key, .unquoted(slurpUntil(.comma, required: false))))
      }
    }

    return attrs
  }
}
