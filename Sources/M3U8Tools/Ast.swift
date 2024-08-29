//
//  Ast.swift
//  M3U8Tools
//
//  Created by Spencer Alger on 8/29/24.
//

struct Ast {
  enum Node: Equatable {
    typealias Attributes = [String: String]
    
    // basic tags
    case EXTM3U
    case EXT_X_VERSION(Int)
    
    // Media Segment
    case mediaSegment([MediaSegmentTag], String)
    enum MediaSegmentTag: Equatable {
      case EXTINF(Double, String?)
      case EXT_X_BYTERANGE(length: Double, offset: Double)
      case EXT_X_DISCONTINUITY
      case EXT_X_KEY(Attributes)
      case EXT_X_MAP(Attributes)
      case EXT_X_PROGRAM_DATE_TIME(String)
      case EXT_X_DATERANGE(Attributes)
    }
    
    // Media Playlist Tags
    case EXT_X_TARGETDURATION(Int)
    case EXT_X_MEDIA_SEQUENCE(Int)
    case EXT_X_DISCONTINUITY_SEQUENCE(Int)
    case EXT_X_ENDLIST
    case EXT_X_PLAYLIST_TYPE(String)
    case EXT_X_I_FRAMES_ONLY
    
    // Master Playlist Tags
    case EXT_X_MEDIA(Attributes)
    case EXT_X_STREAM_INF(Attributes, String)
    case EXT_X_I_FRAME_STREAM_INF(Attributes)
    case EXT_X_SESSION_DATA(Attributes)
    case EXT_X_SESSION_KEY(Attributes)
    
    // Media or Master Playlist Tags
    case EXT_X_INDEPENDENT_SEGMENTS
    case EXT_X_START(Attributes)
    
    // tokens
    case unknown(String)
    case resolution(width: Int, height: Int)
  }

  static func parse(_ input: String) throws(ParseError) -> [Node] {
    let parser = Parser(input)
    var nodes = [Node]()
    
    var mediaSegmentInProgress: [Node.MediaSegmentTag]?
    
    while !parser.isAtEnd {
      if parser.char != "#" {
        parser.skip(.whitespace)
        
        if parser.eol != nil {
          // skip empty line
          try parser.endLine()
          continue
        }
        
        // collect URL for media segment in progress
        if let msNodes = mediaSegmentInProgress {
          mediaSegmentInProgress = nil
          try nodes.append(.mediaSegment(msNodes, parser.slurpLine()))
          continue
        }
        
        throw ParseError.expectedEndOfLine(at: parser.offset)
      }
      
      try parser.skip(control: "#")
      let tag = parser.slurp(.tagName)
      
      switch tag {
        case "EXTM3U":
          nodes.append(.EXTM3U)
          try parser.endLine()
          
        case "EXT-X-VERSION":
          try parser.skip(.colon)
          try nodes.append(.EXT_X_VERSION(parser.slurpInt()))
          try parser.endLine()
          
        case "EXTINF":
          if mediaSegmentInProgress == nil { mediaSegmentInProgress = [] }
          
          try parser.skip(.colon)
          let duration = try parser.slurpDouble()
          if parser.isEol {
            mediaSegmentInProgress?.append(.EXTINF(duration, nil))
            try parser.endLine()
            continue
          }
          
          try parser.skip(.comma)
          try mediaSegmentInProgress?.append(.EXTINF(duration, parser.slurpLine()))
          
        case "EXT-X-BYTERANGE":
          if mediaSegmentInProgress == nil { mediaSegmentInProgress = [] }
          try parser.skip(.colon)
          
          let length = try parser.slurpDouble()
          if parser.isEol {
            mediaSegmentInProgress?.append(.EXT_X_BYTERANGE(length: length, offset: 0))
            try parser.endLine()
            continue
          }
          
          try parser.skip(control: "@")
          let offset = try parser.slurpDouble()
          mediaSegmentInProgress?.append(.EXT_X_BYTERANGE(length: length, offset: offset))
          try parser.endLine()
          
        case "EXT-X-DISCONTINUITY":
          if mediaSegmentInProgress == nil { mediaSegmentInProgress = [] }
          mediaSegmentInProgress?.append(.EXT_X_DISCONTINUITY)
          try parser.endLine()
          
        case "EXT-X-KEY":
          if mediaSegmentInProgress == nil { mediaSegmentInProgress = [] }
          try parser.skip(.colon)
          try mediaSegmentInProgress?.append(.EXT_X_KEY(parser.slurpAttributes()))
          
        case "EXT-X-MAP":
          if mediaSegmentInProgress == nil { mediaSegmentInProgress = [] }
          try parser.skip(.colon)
          try mediaSegmentInProgress?.append(.EXT_X_MAP(parser.slurpAttributes()))
          
        case "EXT-X-PROGRAM-DATE-TIME":
          if mediaSegmentInProgress == nil { mediaSegmentInProgress = [] }
          try parser.skip(.colon)
          try mediaSegmentInProgress?.append(.EXT_X_PROGRAM_DATE_TIME(parser.slurpLine()))
          
        case "EXT-X-DATERANGE":
          if mediaSegmentInProgress == nil { mediaSegmentInProgress = [] }
          try parser.skip(.colon)
          try mediaSegmentInProgress?.append(.EXT_X_DATERANGE(parser.slurpAttributes()))
          
        case "EXT-X-TARGETDURATION":
          try parser.skip(.colon)
          try nodes.append(.EXT_X_TARGETDURATION(parser.slurpInt()))
          try parser.endLine()
          
        case "EXT-X-MEDIA-SEQUENCE":
          try parser.skip(.colon)
          try nodes.append(.EXT_X_MEDIA_SEQUENCE(parser.slurpInt()))
          try parser.endLine()
          
        case "EXT-X-DISCONTINUITY-SEQUENCE":
          try parser.skip(.colon)
          try nodes.append(.EXT_X_DISCONTINUITY_SEQUENCE(parser.slurpInt()))
          try parser.endLine()
          
        case "EXT-X-ENDLIST":
          nodes.append(.EXT_X_ENDLIST)
          try parser.endLine()
          
        case "EXT-X-PLAYLIST-TYPE":
          try parser.skip(.colon)
          try nodes.append(.EXT_X_PLAYLIST_TYPE(parser.slurpLine()))
          
        case "EXT-X-I-FRAMES-ONLY":
          nodes.append(.EXT_X_I_FRAMES_ONLY)
          try parser.endLine()

        case "EXT-X-MEDIA":
          try parser.skip(.colon)
          try nodes.append(.EXT_X_MEDIA(parser.slurpAttributes()))
          
        case "EXT-X-STREAM-INF":
          try parser.skip(.colon)
          try nodes.append(.EXT_X_STREAM_INF(parser.slurpAttributes(), parser.slurpLine()))
          
        case "EXT-X-I-FRAME-STREAM-INF":
          try parser.skip(.colon)
          try nodes.append(.EXT_X_I_FRAME_STREAM_INF(parser.slurpAttributes()))
          
        case "EXT-X-SESSION-DATA":
          try parser.skip(.colon)
          try nodes.append(.EXT_X_SESSION_DATA(parser.slurpAttributes()))
          
        case "EXT-X-SESSION-KEY":
          try parser.skip(.colon)
          try nodes.append(.EXT_X_SESSION_KEY(parser.slurpAttributes()))
          
        case "EXT-X-INDEPENDENT-SEGMENTS":
          nodes.append(.EXT_X_INDEPENDENT_SEGMENTS)
          
        case "EXT-X-START":
          try parser.skip(.colon)
          try nodes.append(.EXT_X_START(parser.slurpAttributes()))
          
        default:
          continue
      }
    }
    
    return nodes
  }
  
  let nodes: [Node]
}
