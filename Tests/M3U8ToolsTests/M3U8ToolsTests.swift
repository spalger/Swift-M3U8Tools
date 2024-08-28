@testable import M3U8Tools
import Testing
import XCTest

@Test func lineParsing() async throws {
  let parser = M3U8ToolsParser()
  parser.push(chunk: "line1\nline2\nline3\n")
  #expect(parser.lines == ["line1", "line2", "line3"])
}
