//
//  PaletteStore.swift
//  CS193PEmojiArt
//
//  Created by Murty Gudipati on 19/06/21.
//

import SwiftUI

struct Palette: Identifiable, Codable, Hashable {
  var id = UUID()
  var name: String
  var emojis: String

  fileprivate init(name: String, emojis: String) {
    self.name = name
    self.emojis = emojis
  }
}

class PaletteStore: ObservableObject {
  let name: String

  @Published var palettes = [Palette]() {
    didSet {
      storeInUserDefaults()
    }
  }

  var userDefaultsKey: String {
    "PaletteStore: " + name
  }

  private func storeInUserDefaults() {
    UserDefaults.standard.set(try? JSONEncoder().encode(palettes), forKey: userDefaultsKey)
  }

  private func restoreFromUserDefaults() {
    if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
       let decoded = try? JSONDecoder().decode([Palette].self, from: data) {
      palettes = decoded
    }
  }

  init(named name: String) {
    self.name = name
    restoreFromUserDefaults()
    if palettes.isEmpty {
      insertPallete(named: "Vehicles", emojis: "🚗✈️🛵🚜🚊🚀⛵️🚤🛥🚁")
      insertPallete(named: "Animals", emojis: "🐶🐱🐭🐹🐰🦊🐻🐼🐻‍❄️🐨")
      insertPallete(named: "Activities", emojis: "⚽️🏀🏈⚾️🥎🎾🏐🏉🥏🎱")
      insertPallete(named: "Halloween", emojis: "🎃👻💀☠️🕷")
      insertPallete(named: "Flags", emojis: "🇬🇧🏴󠁧󠁢󠁥󠁮󠁧󠁿🇺🇸🇨🇮🇲🇰🇯🇵🇳🇴🇨🇦🇵🇰🇮🇳")
      insertPallete(named: "Smileys", emojis: "😀😆😇🤣🥲😍🤪😛😎😝😡😨😈")
    }
  }

  // MARK: - Intent(s)
  func palette(at index: Int) -> Palette {
    let safeIndex = min(max(index, 0), palettes.count - 1)
    return palettes[safeIndex]
  }

  func removePalette(at index: Int) -> Int {
    if palettes.count > 1, palettes.indices.contains(index) {
      palettes.remove(at: index)
    }
    return index % palettes.count
  }

  func insertPallete(named name: String, emojis: String? = nil, at index: Int = 0) {
    let palette = Palette(name: name, emojis: emojis ?? "")
    let safeIndex = min(max(index, 0), palettes.count)
    palettes.insert(palette, at: safeIndex)
  }
}
