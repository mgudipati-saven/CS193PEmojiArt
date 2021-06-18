//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/26/21.
//  Copyright © 2021 Stanford University. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentView: View {
  @ObservedObject var document: EmojiArtDocument

  let defaultEmojiFontSize: CGFloat = 40

  @State private var selectedEmojis = Set<EmojiArt.Emoji>()

  var body: some View {
    VStack(spacing: 0) {
      documentBody
      palette
    }
  }

  var documentBody: some View {
    GeometryReader { geometry in
      ZStack {
        Color.white.overlay(
          OptionalImage(uiImage: document.backgroundImage)
            .scaleEffect(zoomScale)
            .position(convertFromEmojiCoordinates((0,0), in: geometry))
        )
        .gesture(doubleTapToZoom(in: geometry.size).exclusively(before: tapGesture()))

        if document.backgroundImageFetchStatus == .fetching {
          ProgressView().scaleEffect(2)
        } else {
          ForEach(document.emojis) { emoji in
            Text(emoji.text)
              .padding()
              .background(
                isSelected(emoji)
                  ? Circle().stroke(Color.red, lineWidth: 2).frame(width: CGFloat(emoji.size + 5))
                  : nil)
              .font(.system(size: fontSize(for: emoji)))
              .scaleEffect(zoomScale)
              .position(position(for: emoji, in: geometry.size))
              .onTapGesture {
                selectedEmojis.toggleMembership(of: emoji)
              }
              .gesture(emojiDragGesture(emoji))
          }
        }
      }
      .clipped()
      .onDrop(of: [.plainText,.url,.image], isTargeted: nil) { providers, location in
        drop(providers: providers, at: location, in: geometry)
      }
      .gesture(panGesture().simultaneously(with: zoomGesture()))
    }
  }

  // MARK: - Drag and Drop

  private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
    var found = providers.loadObjects(ofType: URL.self) { url in
      document.setBackground(.url(url.imageURL))
    }
    if !found {
      found = providers.loadObjects(ofType: UIImage.self) { image in
        if let data = image.jpegData(compressionQuality: 1.0) {
          document.setBackground(.imageData(data))
        }
      }
    }
    if !found {
      found = providers.loadObjects(ofType: String.self) { string in
        if let emoji = string.first, emoji.isEmoji {
          document.addEmoji(
            String(emoji),
            at: convertToEmojiCoordinates(location, in: geometry),
            size: defaultEmojiFontSize / zoomScale
          )
        }
      }
    }
    return found
  }

  // MARK: - Positioning/Sizing Emoji

//  private func position(for emoji: EmojiArt.Emoji, in geometry: GeometryProxy) -> CGPoint {
//    convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
//  }

  private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
      var location = emoji.location
      location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
      location = CGPoint(x: location.x + size.width / 2, y: location.y + size.height / 2)
      location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
      return location
  }

  private func fontSize(for emoji: EmojiArt.Emoji) -> CGFloat {
    CGFloat(emoji.size)
  }

  private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
    let center = geometry.frame(in: .local).center
    let location = CGPoint(
      x: (location.x - panOffset.width - center.x) / zoomScale,
      y: (location.y - panOffset.height - center.y) / zoomScale
    )
    return (Int(location.x), Int(location.y))
  }

  private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
    let center = geometry.frame(in: .local).center
    return CGPoint(
      x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
      y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
    )
  }

  // MARK: - Zooming

  @State private var steadyStateZoomScale: CGFloat = 1
  @GestureState private var gestureZoomScale: CGFloat = 1

  private var zoomScale: CGFloat {
    steadyStateZoomScale * (selectedEmojis.isEmpty ? gestureZoomScale : 1)
  }

  private func zoomGesture() -> some Gesture {
    MagnificationGesture()
      .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
        gestureZoomScale = latestGestureScale
      }
      .onEnded { gestureScaleAtEnd in
        if selectedEmojis.isEmpty {
          steadyStateZoomScale *= gestureScaleAtEnd
        } else {
          selectedEmojis.forEach { emoji in
            document.scaleEmoji(emoji, by: gestureScaleAtEnd)
          }
        }
      }
  }

  private func doubleTapToZoom(in size: CGSize) -> some Gesture {
    TapGesture(count: 2)
      .onEnded {
        withAnimation {
          zoomToFit(document.backgroundImage, in: size)
        }
      }
  }

  private func zoomToFit(_ image: UIImage?, in size: CGSize) {
    if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0  {
      let hZoom = size.width / image.size.width
      let vZoom = size.height / image.size.height
      steadyStatePanOffset = .zero
      steadyStateZoomScale = min(hZoom, vZoom)
    }
  }

  // MARK: - Panning

  @State private var steadyStatePanOffset: CGSize = CGSize.zero
  @GestureState private var gesturePanOffset: CGSize = CGSize.zero

  private var panOffset: CGSize {
    (steadyStatePanOffset + gesturePanOffset) * zoomScale
  }

  private func panGesture() -> some Gesture {
    DragGesture()
      .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
        gesturePanOffset = latestDragGestureValue.translation / zoomScale
      }
      .onEnded { finalDragGestureValue in
        steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
      }
  }

  @GestureState private var gestureDragOffset: CGSize = CGSize.zero

  private func emojiDragGesture(_ emoji: EmojiArt.Emoji) -> some Gesture {
    DragGesture()
      .updating($gesturePanOffset) { latestDragGestureValue, gestureDragOffset, _ in
        gestureDragOffset = latestDragGestureValue.translation / zoomScale
      }
      .onEnded { finalDragGestureValue in
        let dragDistance = finalDragGestureValue.translation / zoomScale
        document.moveEmoji(emoji, by: dragDistance)
      }
  }

  // MARK: - Tapping

  private func isSelected(_ emoji: EmojiArt.Emoji) -> Bool {
    selectedEmojis.contains(emoji)
  }

  private func tapGesture() -> some Gesture {
    TapGesture().onEnded{
      selectedEmojis.removeAll()
    }
  }

  // MARK: - Palette

  var palette: some View {
    ScrollingEmojisView(emojis: testEmojis)
      .font(.system(size: defaultEmojiFontSize))
  }

  let testEmojis = "😀😷🦠💉👻👀🐶🌲🌎🌞🔥🍎⚽️🚗🚓🚲🛩🚁🚀🛸🏠⌚️🎁🗝🔐❤️⛔️❌❓✅⚠️🎶➕➖🏳️"
}

struct ScrollingEmojisView: View {
  let emojis: String

  var body: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(emojis.map { String($0) }, id: \.self) { emoji in
          Text(emoji)
            .onDrag { NSItemProvider(object: emoji as NSString) }
        }
      }
    }
  }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}


struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    EmojiArtDocumentView(document: EmojiArtDocument())
  }
}
