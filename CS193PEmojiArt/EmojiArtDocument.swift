//
//  EmojiArtDocument.swift
//  CS193PEmojiArt
//
//  Created by Murty Gudipati on 15/06/21.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
  @Published private(set) var emojiArt: EmojiArt

  init() {
    emojiArt = EmojiArt()
    emojiArt.addEmoji("😀", at: (-200, -100), size: 80)
    emojiArt.addEmoji("😍", at: (50, 100), size: 40)
  }

  var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
  var background: EmojiArt.Background { emojiArt.background }

  // MARK: - Intent(s)
  func setBackground(_ background: EmojiArt.Background) {
    emojiArt.background = background
  }

  func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat) {
    emojiArt.addEmoji(emoji, at: location, size: Int(size))
  }

  func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
    if let index = emojiArt.emojis.index(matching: emoji) {
      emojiArt.emojis[index].x += Int( offset.width)
      emojiArt.emojis[index].y += Int( offset.height)
    }
  }

  func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
    if let index = emojiArt.emojis.index(matching: emoji) {
      emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
    }
  }
}
