//
//  PaletteChooser.swift
//  CS193PEmojiArt
//
//  Created by Murty Gudipati on 20/06/21.
//

import SwiftUI

struct PaletteChooser: View {
  var emojiFontSize: CGFloat = 40
  var emojiFont: Font { .system(size: emojiFontSize) }

  @EnvironmentObject var store: PaletteStore

  var body: some View {
    HStack {
      paletteControlButton
      body(for: store.palette(at: chosenPaletteIndex))
    }
    .clipped()
  }

  func body(for palette: Palette) -> some View {
    HStack {
      Text(palette.name).font(.system(.title, design: .rounded))
      ScrollingEmojisView(emojis: palette.emojis).font(emojiFont)
    }
    .id(palette.id)
    .transition(rollTranision)
    .popover(item: $paletteToEdit) { palette in
      PaletteEditor(palette: $store.palettes[palette])
    }
    .sheet(isPresented: $managing) {
      PaletteManager()
    }
  }

  @State private var paletteToEdit: Palette?
  @State private var chosenPaletteIndex = 0
  @State private var managing = false

  var paletteControlButton: some View {
    Button {
      withAnimation {
        chosenPaletteIndex = (chosenPaletteIndex + 1) % store.palettes.count
      }
    } label: {
      Image(systemName: "paintpalette")
    }
    .font(emojiFont)
    .contextMenu {
      contextMenu
    }
  }

  @ViewBuilder
  var contextMenu: some View {
    AnimatedActionButton(title: "Edit", systemImage: "pencil") {
      paletteToEdit = store.palette(at: chosenPaletteIndex)
    }
    AnimatedActionButton(title: "New", systemImage: "plus") {
      store.insertPallete(named: "New", emojis: "", at: chosenPaletteIndex)
    }
    AnimatedActionButton(title: "Delete", systemImage: "minus.circle") {
      chosenPaletteIndex = store.removePalette(at: chosenPaletteIndex)
    }
    AnimatedActionButton(title: "Manager", systemImage: "slider.vertical.3") {
      managing.toggle()
    }
    gotoMenu
  }

  var gotoMenu: some View {
    Menu {
      ForEach(store.palettes.indices) { index in
        AnimatedActionButton(title: store.palette(at: index).name) {
          chosenPaletteIndex = index
        }
      }
    } label: {
      Label("Go To", systemImage: "text.insert")
    }
  }

  var rollTranision: AnyTransition {
    AnyTransition.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top))
  }
}

struct ScrollingEmojisView: View {
  let emojis: String

  var body: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(emojis.withNoRepeatedCharacters.map { String($0) }, id: \.self) { emoji in
          Text(emoji)
            .onDrag { NSItemProvider(object: emoji as NSString) }
        }
      }
    }
  }
}

struct PaletteChooser_Previews: PreviewProvider {
  static var previews: some View {
    PaletteChooser()
  }
}
