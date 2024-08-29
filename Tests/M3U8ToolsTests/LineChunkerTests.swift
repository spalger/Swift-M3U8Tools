@testable import M3U8Tools
import Testing
import XCTest

struct LineChunkerTests {
  @Test func weirdChunks() {
    func testIncomplete(_ chunks: [String], _ expectedLines: [String], _ expectedPartial: String) {
      let chunker = LineChunker()
      var lines = [String]()
      
      for chunk in chunks {
        lines += chunker.push(chunk: chunk)
      }
      
      #expect(lines == expectedLines)
      #expect(chunker.partialLine == expectedPartial)
    }
    
    testIncomplete(["line1\nline2\nline3\n"], ["line1", "line2", "line3"], "")
    testIncomplete(["line1\nline2\nline3"], ["line1", "line2"], "line3")
    testIncomplete(["line1\nlin", "e2\nline3"], ["line1", "line2"], "line3")
    testIncomplete(["line1\nline2\nline"], ["line1", "line2"], "line")
    testIncomplete(["line1\nline2", "\nline"], ["line1", "line2"], "line")
  }
  
  @Test func chunksWithNoFinalNewline() {
    func testWithEnd(_ chunks: [String], _ lines: [String], _ endResult: [String]) {
      let chunker = LineChunker()
      var returned = [String]()
      
      for chunk in chunks {
        returned += chunker.push(chunk: chunk)
      }
      
      #expect(returned == lines)
      #expect(chunker.end() == endResult)
    }
    
    testWithEnd(["foo", "bar", "baz"], [], ["foobarbaz"])
    testWithEnd(["foo", "ba\nr", "baz"], ["fooba"], ["rbaz"])
    testWithEnd(["fo\no", "ba\nr", "baz"], ["fo", "oba"], ["rbaz"])
  }
}
