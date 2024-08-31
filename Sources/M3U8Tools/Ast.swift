//
//  Ast.swift
//  M3U8Tools
//
//  Created by Spencer Alger on 8/29/24.
//

public struct Ast: Equatable {
  let nodes: [Node]
}

// MARK: Parsing

public extension Ast {
  enum Node: Equatable {
    public struct Attribute: Equatable {
      let key: String
      let value: Value

      init(_ key: String, _ value: Value) {
        self.key = key
        self.value = value
      }

      public enum Value: Equatable {
        case quoted(String)
        case unquoted(String)
      }
    }

    // basic tags
    case EXTM3U
    case EXT_X_VERSION(Int)

    // Media Segment
    case mediaSegment([MediaSegmentTag], String)
    public enum MediaSegmentTag: Equatable {
      case EXTINF(Double, String?)
      case EXT_X_BYTERANGE(length: Double, offset: Double?)
      case EXT_X_DISCONTINUITY
      case EXT_X_KEY([Attribute])
      case EXT_X_MAP([Attribute])
      case EXT_X_PROGRAM_DATE_TIME(String)
      case EXT_X_DATERANGE([Attribute])
    }

    // Media Playlist Tags
    case EXT_X_TARGETDURATION(Int)
    case EXT_X_MEDIA_SEQUENCE(Int)
    case EXT_X_DISCONTINUITY_SEQUENCE(Int)
    case EXT_X_ENDLIST
    case EXT_X_PLAYLIST_TYPE(String)
    case EXT_X_I_FRAMES_ONLY

    // Master Playlist Tags
    case EXT_X_MEDIA([Attribute])
    case EXT_X_STREAM_INF([Attribute], String)
    case EXT_X_I_FRAME_STREAM_INF([Attribute])
    case EXT_X_SESSION_DATA([Attribute])
    case EXT_X_SESSION_KEY([Attribute])

    // Media or Master Playlist Tags
    case EXT_X_INDEPENDENT_SEGMENTS
    case EXT_X_START([Attribute])
  }

  static func parse(_ input: String) throws(ParseError) -> Ast {
    let p = Parser(input)
    var nodes = [Node]()

    var partialSegment: [Node.MediaSegmentTag]?

    while !p.isAtEnd {
      if p.char != "#" {
        p.skip(.whitespace)

        if p.eol != nil {
          // skip empty line
          try p.endLine()
          continue
        }

        // collect URL for media segment in progress
        if let msNodes = partialSegment {
          partialSegment = nil
          try nodes.append(.mediaSegment(msNodes, p.slurpLine()))
          continue
        }

        throw ParseError.expectedEndOfLine(at: p.offset)
      }

      try p.skip(control: "#")
      let tag = p.slurp(.tagName)

      switch tag {
        case "EXTM3U":
          nodes.append(.EXTM3U)
          try p.endLine()

        case "EXT-X-VERSION":
          try p.skip(.colon)
          try nodes.append(.EXT_X_VERSION(p.slurpInt()))
          try p.endLine()

        case "EXTINF":
          partialSegment = partialSegment ?? []
          try p.skip(.colon)

          let duration = try p.slurpDouble()
          if p.isEol {
            partialSegment?.append(.EXTINF(duration, nil))
            try p.endLine()
            continue
          }

          try p.skip(.comma)
          try partialSegment?.append(.EXTINF(duration, p.slurpLine()))

        case "EXT-X-BYTERANGE":
          partialSegment = partialSegment ?? []
          try p.skip(.colon)

          let length = try p.slurpDouble()
          if p.isEol {
            partialSegment?.append(.EXT_X_BYTERANGE(length: length, offset: nil))
            try p.endLine()
            continue
          }

          try p.skip(control: "@")
          let offset = try p.slurpDouble()
          partialSegment?.append(.EXT_X_BYTERANGE(length: length, offset: offset))
          try p.endLine()

        case "EXT-X-DISCONTINUITY":
          partialSegment = partialSegment ?? []
          partialSegment?.append(.EXT_X_DISCONTINUITY)
          try p.endLine()

        case "EXT-X-KEY":
          partialSegment = partialSegment ?? []
          try p.skip(.colon)
          try partialSegment?.append(.EXT_X_KEY(p.slurpAttributes()))

        case "EXT-X-MAP":
          partialSegment = partialSegment ?? []
          try p.skip(.colon)
          try partialSegment?.append(.EXT_X_MAP(p.slurpAttributes()))

        case "EXT-X-PROGRAM-DATE-TIME":
          partialSegment = partialSegment ?? []
          try p.skip(.colon)
          try partialSegment?.append(.EXT_X_PROGRAM_DATE_TIME(p.slurpLine()))

        case "EXT-X-DATERANGE":
          partialSegment = partialSegment ?? []
          try p.skip(.colon)
          try partialSegment?.append(.EXT_X_DATERANGE(p.slurpAttributes()))

        case "EXT-X-TARGETDURATION":
          try p.skip(.colon)
          try nodes.append(.EXT_X_TARGETDURATION(p.slurpInt()))
          try p.endLine()

        case "EXT-X-MEDIA-SEQUENCE":
          try p.skip(.colon)
          try nodes.append(.EXT_X_MEDIA_SEQUENCE(p.slurpInt()))
          try p.endLine()

        case "EXT-X-DISCONTINUITY-SEQUENCE":
          try p.skip(.colon)
          try nodes.append(.EXT_X_DISCONTINUITY_SEQUENCE(p.slurpInt()))
          try p.endLine()

        case "EXT-X-ENDLIST":
          nodes.append(.EXT_X_ENDLIST)
          try p.endLine()

        case "EXT-X-PLAYLIST-TYPE":
          try p.skip(.colon)
          try nodes.append(.EXT_X_PLAYLIST_TYPE(p.slurpLine()))

        case "EXT-X-I-FRAMES-ONLY":
          nodes.append(.EXT_X_I_FRAMES_ONLY)
          try p.endLine()

        case "EXT-X-MEDIA":
          try p.skip(.colon)
          try nodes.append(.EXT_X_MEDIA(p.slurpAttributes()))

        case "EXT-X-STREAM-INF":
          try p.skip(.colon)
          try nodes.append(.EXT_X_STREAM_INF(p.slurpAttributes(), p.slurpLine()))

        case "EXT-X-I-FRAME-STREAM-INF":
          try p.skip(.colon)
          try nodes.append(.EXT_X_I_FRAME_STREAM_INF(p.slurpAttributes()))

        case "EXT-X-SESSION-DATA":
          try p.skip(.colon)
          try nodes.append(.EXT_X_SESSION_DATA(p.slurpAttributes()))

        case "EXT-X-SESSION-KEY":
          try p.skip(.colon)
          try nodes.append(.EXT_X_SESSION_KEY(p.slurpAttributes()))

        case "EXT-X-INDEPENDENT-SEGMENTS":
          nodes.append(.EXT_X_INDEPENDENT_SEGMENTS)

        case "EXT-X-START":
          try p.skip(.colon)
          try nodes.append(.EXT_X_START(p.slurpAttributes()))

        default:
          continue
      }
    }

    return .init(nodes: nodes)
  }
}

// MARK: Printing

public extension Ast {
  static func print(_ ast: Ast) -> String {
    ast.nodes
      .map { print($0) }
      .joined(separator: "\n")
  }

  static func print(_ node: Node) -> String {
    switch node {
      case .EXTM3U:
        "#EXTM3U"

      case .EXT_X_VERSION(let version):
        "#EXT-X-VERSION:\(version)"

      case .mediaSegment(let tags, let url):
        (tags.map { print($0) } + [url])
          .joined(separator: "\n")

      case .EXT_X_TARGETDURATION(let int):
        "#EXT-X-TARGETDURATION:\(int)"

      case .EXT_X_MEDIA_SEQUENCE(let int):
        "#EXT-X-MEDIA-SEQUENCE:\(int)"

      case .EXT_X_DISCONTINUITY_SEQUENCE(let int):
        "#EXT-X-DISCONTINUITY-SEQUENCE:\(int)"

      case .EXT_X_ENDLIST:
        "#EXT-X-ENDLIST"

      case .EXT_X_PLAYLIST_TYPE(let string):
        "#EXT-X-PLAYLIST-TYPE:\(string)"

      case .EXT_X_I_FRAMES_ONLY:
        "#EXT-X-I-FRAMES-ONLY"

      case .EXT_X_MEDIA(let attributes):
        "#EXT-X-MEDIA:\(print(attributes))"

      case .EXT_X_STREAM_INF(let attributes, let uri):
        "#EXT-X-STREAM-INF:\(print(attributes))\n\(uri)"

      case .EXT_X_I_FRAME_STREAM_INF(let attributes):
        "#EXT-X-I-FRAME-STREAM-INF:\(print(attributes))"

      case .EXT_X_SESSION_DATA(let attributes):
        "#EXT-X-SESSION-DATA:\(print(attributes))"

      case .EXT_X_SESSION_KEY(let attributes):
        "#EXT-X-SESSION-KEY:\(print(attributes))"

      case .EXT_X_INDEPENDENT_SEGMENTS:
        "#EXT-X-INDEPENDENT-SEGMENTS"

      case .EXT_X_START(let attributes):
        "#EXT-X-START:\(print(attributes))"
    }
  }

  static func print(_ tag: Node.MediaSegmentTag) -> String {
    switch tag {
      case .EXTINF(let double, let string):
        return "#EXTINF:\(double),\(string ?? "")"

      case .EXT_X_BYTERANGE(let length, let offset):
        let base = "#EXT-X-BYTERANGE:\(length)"
        if let offset {
          return "\(base)@\(offset)"
        } else {
          return base
        }

      case .EXT_X_DISCONTINUITY:
        return "#EXT-X-DISCONTINUITY"

      case .EXT_X_KEY(let attributes):
        return "#EXT-X-KEY:\(print(attributes))"

      case .EXT_X_MAP(let attributes):
        return "#EXT-X-MAP:\(print(attributes))"

      case .EXT_X_PROGRAM_DATE_TIME(let dateStr):
        return "#EXT-X-PROGRAM-DATE-TIME:\(dateStr)"

      case .EXT_X_DATERANGE(let attributes):
        return "#EXT-X-DATERANGE:\(print(attributes))"
    }
  }

  static func print(_ attributes: [Node.Attribute]) -> String {
    attributes
      .map { "\($0.key)=\(print($0.value))" }
      .joined(separator: ",")
  }

  static func print(_ value: Node.Attribute.Value) -> String {
    switch value {
      case .quoted(let string):
        "\"\(string)\""
      case .unquoted(let string):
        string
    }
  }
}
