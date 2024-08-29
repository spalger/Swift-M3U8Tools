//
//  Err.swift
//  M3U8Tools
//
//  Created by Spencer Alger on 8/28/24.
//

enum ParseError: Error, Equatable {
  case invalidNumber(at: Int?, String)
  case expectedEndOfLine(at: Int?)
  case unexpectedCharacter(at: Int?, Character, expected: Character)
  case unexpectedEndOfString(at: Int?, expected: Character)
}
