//
//  PaletteManager.swift
//  CS193PEmojiArt
//
//  Created by Murty Gudipati on 20/06/21.
//

import SwiftUI

struct PaletteManager: View {
  @EnvironmentObject var store: PaletteStore
  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    NavigationView {
      List {
        ForEach(store.palettes) { palette in
          NavigationLink(destination: PaletteEditor(palette: $store.palettes[palette])) {
            VStack(alignment: .leading) {
              Text(palette.name)
              Text(palette.emojis)
            }
          }
        }
        .onDelete { indexSet in
          store.palettes.remove(atOffsets: indexSet)
        }
        .onMove { indexSet, newOffset in
          store.palettes.move(fromOffsets: indexSet, toOffset: newOffset)
        }
      }
      .navigationTitle("Manage Palettes")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem { EditButton() }
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Close") { presentationMode.wrappedValue.dismiss() }
        }
      }
    }
  }
}

struct PaletteManager_Previews: PreviewProvider {
  static var previews: some View {
    PaletteManager()
      .previewDevice("iPhone 11")
      .environmentObject(PaletteStore(named: "Preview"))
  }
}
