//
//  CS193PEmojiArtApp.swift
//  CS193PEmojiArt
//
//  Created by Murty Gudipati on 15/06/21.
//

import SwiftUI

@main
struct CS193PEmojiArtApp: App {
  let document = EmojiArtDocument()

  var body: some Scene {
    WindowGroup {
      EmojiArtDocumentView(document: document)
    }
  }
}
