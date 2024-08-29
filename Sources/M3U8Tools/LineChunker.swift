//
//  LineChunker.swift
//  M3U8Tools
//
//  Created by Spencer Alger on 8/28/24.
//

class LineChunker {
  private(set) var partialLine: String = ""

  func push(chunk: String) -> [String] {
    var lines = [String]()
    var buffer = String.SubSequence(partialLine + chunk)

    while let index = buffer.firstIndex(of: "\n") {
      lines.append(String(buffer.prefix(upTo: index)))
      buffer = buffer.suffix(from: buffer.index(after: index))
    }

    partialLine = String(buffer)
    return lines
  }

  func end() -> [String] {
    if partialLine.isEmpty {
      return []
    }

    let finalLine = partialLine
    partialLine = ""
    return [finalLine]
  }
}
