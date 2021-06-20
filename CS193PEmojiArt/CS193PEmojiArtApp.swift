//
//  CS193PEmojiArtApp.swift
//  CS193PEmojiArt
//
//  Created by Murty Gudipati on 15/06/21.
//

import SwiftUI

@main
struct CS193PEmojiArtApp: App {
  @StateObject var document = EmojiArtDocument()
  @StateObject var paletteStore = PaletteStore(named: "default")

  var body: some Scene {
    WindowGroup {
      EmojiArtDocumentView(document: document)
        .environmentObject(paletteStore)
    }
  }
}
