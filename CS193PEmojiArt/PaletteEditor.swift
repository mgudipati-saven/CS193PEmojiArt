//
//  PaletteEditor.swift
//  CS193PEmojiArt
//
//  Created by Murty Gudipati on 20/06/21.
//

import SwiftUI

struct PaletteEditor: View {
  @Binding var palette: Palette

  var body: some View {
    Form {
      nameSection
      addEmojisSection
      removeEmojiSection
    }
    .navigationTitle("Edit \(palette.name)")
    .frame(minWidth: 300, minHeight: 350)
  }

  var removeEmojiSection: some View {
    Section(header: Text("remove emoji")) {
      let emojis = palette.emojis.withNoRepeatedCharacters.map { String($0) }
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
        ForEach(emojis, id: \.self) { emoji in
          Text(emoji)
            .onTapGesture {
              withAnimation {
                palette.emojis.removeAll(where: { String($0) == emoji })
              }
            }
        }
      }
      .font(.system(size: 40))
    }
  }

  @State private var emojisToAdd = ""

  var addEmojisSection: some View {
    Section(header: Text("add emoji")) {
      TextField("", text: $emojisToAdd)
        .onChange(of: emojisToAdd) { emojis in
          addEmojis(emojis)
        }
    }
  }

  func addEmojis(_ emojis: String) {
    withAnimation {
      palette.emojis = (emojis + palette.emojis)
        .filter { $0.isEmoji }
        .withNoRepeatedCharacters
    }
  }

  var nameSection: some View {
    Section(header: Text("name")) {
      TextField("Name", text: $palette.name)
    }
  }
}

struct PaletteEditor_Previews: PreviewProvider {
  static var previews: some View {
    PaletteEditor(palette: .constant(PaletteStore(named: "Test").palette(at: 2)))
      .previewLayout(.fixed(width: 300, height: 350))
  }
}
