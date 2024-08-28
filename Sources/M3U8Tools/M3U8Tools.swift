// The Swift Programming Language
// https://docs.swift.org/swift-book

class M3U8ToolsParser {
  private var partialLine: String = ""

  public var lines: [String] = []

  init() {}

  func push(chunk: String) {
    var buffer = String.SubSequence(partialLine + chunk)
    while let index = buffer.firstIndex(of: "\n") {
      let line = partialLine.prefix(upTo: index)
      buffer = buffer.suffix(from: partialLine.index(after: index))
      push(line: line)
    }
    partialLine = String(buffer)
  }

  private func push(line: String.SubSequence) {
    lines.append(String(line))
  }
}
