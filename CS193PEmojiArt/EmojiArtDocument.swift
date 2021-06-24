//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/26/21.
//  Copyright © 2021 Stanford University. All rights reserved.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject
{
  @Published private(set) var emojiArt: EmojiArt {
    didSet {
      scheduleAutosave()
      if emojiArt.background != oldValue.background {
        fetchBackgroundImageDataIfNecessary()
      }
    }
  }

  init() {
    if let url = Autosave.url, let autosavedEmojiArt = try? EmojiArt(url: url) {
      emojiArt = autosavedEmojiArt
      fetchBackgroundImageDataIfNecessary()
    } else {
      emojiArt = EmojiArt()
    }
  }

  private var autosaveTimer: Timer?

  private func scheduleAutosave() {
    autosaveTimer?.invalidate()
    autosaveTimer = Timer.scheduledTimer(withTimeInterval: Autosave.coalescingInterval, repeats: false) { _ in
      self.autosave()
    }
  }

  private struct Autosave {
    static let filename = "Autosaved.emojiart"
    static var url: URL? {
      let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
      return documentDirectory?.appendingPathComponent(filename)
    }
    static let coalescingInterval = 5.0
  }

  private func autosave() {
    if let url = Autosave.url {
      save(to: url)
    }
  }

  var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
  var background: EmojiArt.Background { emojiArt.background }

  func save(to url: URL) {
    let thisFunction = "\(String(describing: self)).\(#function)"
    do {
      let data: Data = try emojiArt.json()
      print("\(thisFunction) json = \(String(data: data, encoding: .utf8) ?? "nil")")
      try data.write(to: url)
      print("\(thisFunction) success!")
    } catch let encodingError where encodingError is EncodingError {
      print("\(thisFunction) couldn't encode EmojiArt as JSON because \(encodingError.localizedDescription)")
    } catch {
      print("\(thisFunction) error = \(error)")
    }
  }


  // MARK: - Background

  @Published var backgroundImage: UIImage?
  @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle

  enum BackgroundImageFetchStatus {
    case idle
    case fetching
  }

  var cancellables = Set<AnyCancellable>()

  private func fetchBackgroundImageDataIfNecessary() {
    backgroundImage = nil
    switch emojiArt.background {
      case .url(let url):
        // fetch the url
        cancellables.first?.cancel()
        backgroundImageFetchStatus = .fetching
        URLSession.shared.dataTaskPublisher(for: url)
          .map { (data, response) in UIImage(data: data) }
          .replaceError(with: nil)
          .receive(on: DispatchQueue.main)
          .sink(receiveValue: { [weak self] image in
            self?.backgroundImage = image
            self?.backgroundImageFetchStatus = .idle
          })
          .store(in: &cancellables)


//        DispatchQueue.global(qos: .userInitiated).async {
//          let imageData = try? Data(contentsOf: url)
//          DispatchQueue.main.async { [weak self] in
//            if self?.emojiArt.background == EmojiArt.Background.url(url) {
//              self?.backgroundImageFetchStatus = .idle
//              if imageData != nil {
//                self?.backgroundImage = UIImage(data: imageData!)
//              }
//            }
//          }
//        }
      case .imageData(let data):
        backgroundImage = UIImage(data: data)
      case .blank:
        break
    }
  }

  // MARK: - Intent(s)

  func setBackground(_ background: EmojiArt.Background) {
    emojiArt.background = background
  }

  func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat) {
    emojiArt.addEmoji(emoji, at: location, size: Int(size))
  }

  func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
    if let index = emojiArt.emojis.index(matching: emoji) {
      emojiArt.emojis[index].x += Int(offset.width)
      emojiArt.emojis[index].y += Int(offset.height)
    }
  }

  func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
    if let index = emojiArt.emojis.index(matching: emoji) {
      emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
    }
  }
}
