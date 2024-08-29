//
//  AstTest.swift
//  M3U8Tools
//
//  Created by Spencer Alger on 8/29/24.
//

@testable import M3U8Tools
import Testing

// test cases taken from https://www.rfc-editor.org/rfc/rfc8216.html#section-8

struct AstTest {
  @Test func simpleMediaPlaylist() throws {
    let lines = [
      "#EXTM3U",
      "#EXT-X-TARGETDURATION:10",
      "#EXT-X-VERSION:3",
      "#EXTINF:9.009,",
      "http://media.example.com/first.ts",
      "#EXTINF:9.009,",
      "http://media.example.com/second.ts",
      "#EXTINF:3.003,",
      "http://media.example.com/third.ts",
      "#EXT-X-ENDLIST",
    ].joined(separator: "\n")

    let manifest = try Ast.parse(lines)

    #expect(manifest == Ast(nodes: [
      .EXTM3U,
      .EXT_X_TARGETDURATION(10),
      .EXT_X_VERSION(3),
      .mediaSegment([.EXTINF(9.009, "")], "http://media.example.com/first.ts"),
      .mediaSegment([.EXTINF(9.009, "")], "http://media.example.com/second.ts"),
      .mediaSegment([.EXTINF(3.003, "")], "http://media.example.com/third.ts"),
      .EXT_X_ENDLIST,
    ]))

    #expect(Ast.print(manifest) == lines)
  }

  @Test func liveMediaPlaylistUsingHTTPS() throws {
    let lines = [
      "#EXTM3U",
      "#EXT-X-VERSION:3",
      "#EXT-X-TARGETDURATION:8",
      "#EXT-X-MEDIA-SEQUENCE:2680",
      "",
      "#EXTINF:7.975,",
      "https://priv.example.com/fileSequence2680.ts",
      "#EXTINF:7.941,",
      "https://priv.example.com/fileSequence2681.ts",
      "#EXTINF:7.975,",
      "https://priv.example.com/fileSequence2682.ts",
    ].joined(separator: "\n")

    let manifest = try Ast.parse(lines)

    #expect(manifest == Ast(nodes: [
      .EXTM3U,
      .EXT_X_VERSION(3),
      .EXT_X_TARGETDURATION(8),
      .EXT_X_MEDIA_SEQUENCE(2680),
      .mediaSegment([.EXTINF(7.975, "")], "https://priv.example.com/fileSequence2680.ts"),
      .mediaSegment([.EXTINF(7.941, "")], "https://priv.example.com/fileSequence2681.ts"),
      .mediaSegment([.EXTINF(7.975, "")], "https://priv.example.com/fileSequence2682.ts"),
    ]))

    #expect(Ast.print(manifest) == lines.replacingOccurrences(of: "\n\n", with: "\n"))
  }

  @Test func playlistwithEncryptedMediaSegments() throws {
    let lines = [
      "#EXTM3U",
      "#EXT-X-VERSION:3",
      "#EXT-X-MEDIA-SEQUENCE:7794",
      "#EXT-X-TARGETDURATION:15",
      "",
      "#EXT-X-KEY:METHOD=AES-128,URI=\"https://priv.example.com/key.php?r=52\"",
      "",
      "#EXTINF:2.833,",
      "http://media.example.com/fileSequence52-A.ts",
      "#EXTINF:15.0,",
      "http://media.example.com/fileSequence52-B.ts",
      "#EXTINF:13.333,",
      "http://media.example.com/fileSequence52-C.ts",
      "",
      "#EXT-X-KEY:METHOD=AES-128,URI=\"https://priv.example.com/key.php?r=53\"",
      "",
      "#EXTINF:15.0,",
      "http://media.example.com/fileSequence53-A.ts",
    ].joined(separator: "\n")

    let manifest = try Ast.parse(lines)

    #expect(manifest == Ast(nodes: [
      .EXTM3U,
      .EXT_X_VERSION(3),
      .EXT_X_MEDIA_SEQUENCE(7794),
      .EXT_X_TARGETDURATION(15),

      .mediaSegment([
        .EXT_X_KEY([
          .init("METHOD", .unquoted("AES-128")),
          .init("URI", .quoted("https://priv.example.com/key.php?r=52")),
        ]),
        .EXTINF(2.833, ""),
      ], "http://media.example.com/fileSequence52-A.ts"),

      .mediaSegment([
        .EXTINF(15.0, ""),
      ], "http://media.example.com/fileSequence52-B.ts"),

      .mediaSegment([
        .EXTINF(13.333, ""),
      ], "http://media.example.com/fileSequence52-C.ts"),

      .mediaSegment([
        .EXT_X_KEY([
          .init("METHOD", .unquoted("AES-128")),
          .init("URI", .quoted("https://priv.example.com/key.php?r=53")),
        ]),
        .EXTINF(15.0, ""),
      ], "http://media.example.com/fileSequence53-A.ts"),
    ]))

    #expect(Ast.print(manifest) == lines.replacingOccurrences(of: "\n\n", with: "\n"))
  }

  @Test func masterPlaylist() throws {
    let lines = [
      "#EXTM3U",
      "#EXT-X-STREAM-INF:BANDWIDTH=1280000,AVERAGE-BANDWIDTH=1000000",
      "http://example.com/low.m3u8",
      "#EXT-X-STREAM-INF:BANDWIDTH=2560000,AVERAGE-BANDWIDTH=2000000",
      "http://example.com/mid.m3u8",
      "#EXT-X-STREAM-INF:BANDWIDTH=7680000,AVERAGE-BANDWIDTH=6000000",
      "http://example.com/hi.m3u8",
      "#EXT-X-STREAM-INF:BANDWIDTH=65000,CODECS=\"mp4a.40.5\"",
      "http://example.com/audio-only.m3u8",
    ].joined(separator: "\n")

    let manifest = try Ast.parse(lines)

    #expect(manifest == Ast(nodes: [
      .EXTM3U,
      .EXT_X_STREAM_INF([
        .init("BANDWIDTH", .unquoted("1280000")),
        .init("AVERAGE-BANDWIDTH", .unquoted("1000000")),
      ], "http://example.com/low.m3u8"),
      .EXT_X_STREAM_INF([
        .init("BANDWIDTH", .unquoted("2560000")),
        .init("AVERAGE-BANDWIDTH", .unquoted("2000000")),
      ], "http://example.com/mid.m3u8"),
      .EXT_X_STREAM_INF([
        .init("BANDWIDTH", .unquoted("7680000")),
        .init("AVERAGE-BANDWIDTH", .unquoted("6000000")),
      ], "http://example.com/hi.m3u8"),
      .EXT_X_STREAM_INF([
        .init("BANDWIDTH", .unquoted("65000")),
        .init("CODECS", .quoted("mp4a.40.5")),
      ], "http://example.com/audio-only.m3u8"),
    ]))

    #expect(Ast.print(manifest) == lines)
  }

  @Test func masterPlaylistWithIframes() throws {
    let lines = [
      "#EXTM3U",
      "#EXT-X-STREAM-INF:BANDWIDTH=1280000",
      "low/audio-video.m3u8",
      "#EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=86000,URI=\"low/iframe.m3u8\"",
      "#EXT-X-STREAM-INF:BANDWIDTH=2560000",
      "mid/audio-video.m3u8",
      "#EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=150000,URI=\"mid/iframe.m3u8\"",
      "#EXT-X-STREAM-INF:BANDWIDTH=7680000",
      "hi/audio-video.m3u8",
      "#EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=550000,URI=\"hi/iframe.m3u8\"",
      "#EXT-X-STREAM-INF:BANDWIDTH=65000,CODECS=\"mp4a.40.5\"",
      "audio-only.m3u8",
    ].joined(separator: "\n")

    let manifest = try Ast.parse(lines)

    #expect(manifest == Ast(nodes: [
      .EXTM3U,
      .EXT_X_STREAM_INF([
        .init("BANDWIDTH", .unquoted("1280000")),
      ], "low/audio-video.m3u8"),
      .EXT_X_I_FRAME_STREAM_INF([
        .init("BANDWIDTH", .unquoted("86000")),
        .init("URI", .quoted("low/iframe.m3u8")),
      ]),
      .EXT_X_STREAM_INF([
        .init("BANDWIDTH", .unquoted("2560000")),
      ], "mid/audio-video.m3u8"),
      .EXT_X_I_FRAME_STREAM_INF([
        .init("BANDWIDTH", .unquoted("150000")),
        .init("URI", .quoted("mid/iframe.m3u8")),
      ]),
      .EXT_X_STREAM_INF([
        .init("BANDWIDTH", .unquoted("7680000")),
      ], "hi/audio-video.m3u8"),
      .EXT_X_I_FRAME_STREAM_INF([
        .init("BANDWIDTH", .unquoted("550000")),
        .init("URI", .quoted("hi/iframe.m3u8")),
      ]),
      .EXT_X_STREAM_INF([
        .init("BANDWIDTH", .unquoted("65000")),
        .init("CODECS", .quoted("mp4a.40.5")),
      ], "audio-only.m3u8"),
    ]))

    #expect(Ast.print(manifest) == lines)
  }

  @Test func masterPlaylistWithAlternativeAudio() throws {
    let lines = [
      "#EXTM3U",
      "#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"aac\",NAME=\"English\",DEFAULT=YES,AUTOSELECT=YES,LANGUAGE=\"en\",URI=\"main/english-audio.m3u8\"",
      "#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"aac\",NAME=\"Deutsch\",DEFAULT=NO,AUTOSELECT=YES,LANGUAGE=\"de\",URI=\"main/german-audio.m3u8\"",
      "#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"aac\",NAME=\"Commentary\",DEFAULT=NO,AUTOSELECT=NO,LANGUAGE=\"en\",URI=\"commentary/audio-only.m3u8\"",
      "#EXT-X-STREAM-INF:BANDWIDTH=1280000,CODECS=\"...\",AUDIO=\"aac\"",
      "low/video-only.m3u8",
      "#EXT-X-STREAM-INF:BANDWIDTH=2560000,CODECS=\"...\",AUDIO=\"aac\"",
      "mid/video-only.m3u8",
      "#EXT-X-STREAM-INF:BANDWIDTH=7680000,CODECS=\"...\",AUDIO=\"aac\"",
      "hi/video-only.m3u8",
      "#EXT-X-STREAM-INF:BANDWIDTH=65000,CODECS=\"mp4a.40.5\",AUDIO=\"aac\"",
      "main/english-audio.m3u8",
    ].joined(separator: "\n")

    let manifest = try Ast.parse(lines)

    #expect(manifest == Ast(nodes: [
      .EXTM3U,
      .EXT_X_MEDIA([
        .init("TYPE", .unquoted("AUDIO")),
        .init("GROUP-ID", .quoted("aac")),
        .init("NAME", .quoted("English")),
        .init("DEFAULT", .unquoted("YES")),
        .init("AUTOSELECT", .unquoted("YES")),
        .init("LANGUAGE", .quoted("en")),
        .init("URI", .quoted("main/english-audio.m3u8")),
      ]),
      .EXT_X_MEDIA([
        .init("TYPE", .unquoted("AUDIO")),
        .init("GROUP-ID", .quoted("aac")),
        .init("NAME", .quoted("Deutsch")),
        .init("DEFAULT", .unquoted("NO")),
        .init("AUTOSELECT", .unquoted("YES")),
        .init("LANGUAGE", .quoted("de")),
        .init("URI", .quoted("main/german-audio.m3u8")),
      ]),
      .EXT_X_MEDIA([
        .init("TYPE", .unquoted("AUDIO")),
        .init("GROUP-ID", .quoted("aac")),
        .init("NAME", .quoted("Commentary")),
        .init("DEFAULT", .unquoted("NO")),
        .init("AUTOSELECT", .unquoted("NO")),
        .init("LANGUAGE", .quoted("en")),
        .init("URI", .quoted("commentary/audio-only.m3u8")),
      ]),
      .EXT_X_STREAM_INF([
        .init("BANDWIDTH", .unquoted("1280000")),
        .init("CODECS", .quoted("...")),
        .init("AUDIO", .quoted("aac")),
      ], "low/video-only.m3u8"),
      .EXT_X_STREAM_INF([
        .init("BANDWIDTH", .unquoted("2560000")),
        .init("CODECS", .quoted("...")),
        .init("AUDIO", .quoted("aac")),
      ], "mid/video-only.m3u8"),
      .EXT_X_STREAM_INF([
        .init("BANDWIDTH", .unquoted("7680000")),
        .init("CODECS", .quoted("...")),
        .init("AUDIO", .quoted("aac")),
      ], "hi/video-only.m3u8"),
      .EXT_X_STREAM_INF([
        .init("BANDWIDTH", .unquoted("65000")),
        .init("CODECS", .quoted("mp4a.40.5")),
        .init("AUDIO", .quoted("aac")),
      ], "main/english-audio.m3u8"),
    ]))

    #expect(Ast.print(manifest) == lines)
  }
}
