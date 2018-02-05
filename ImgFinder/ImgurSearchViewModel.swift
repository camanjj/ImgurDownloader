//
//  File.swift
//  ImgFinder
//
//  Created by Cameron Jackson on 2/3/18.
//  Copyright © 2018 Cameron Jackson. All rights reserved.
//

import Foundation

protocol ImgurSearchViewModelDelegate: class {
  func updatedResults(for term: String)
}

enum FooterState {
  // note: typing is only used as an initial state
  case typing, loading, empty(String), results
}

class ImgurSearchViewModel {
  private var images: [Image]?
  private var currentPage = 1
  private var currentTerm: String?
  
  // managers
  private var imgurManager = ImgurManager()
  private var historyManager = HistoryManager()
  
  var footerState: FooterState = .typing
  var resultsUpdated: ((String) -> ()) = { _ in } // search results update block
  var historyUpdated: (() -> ()) = { } // history update block
  
  /// Fetches the first page for the text given
  func findImages(for text: String?) {
    
    // only automatic search when there are more than 3 characters in the searchbar
    guard let text = text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
      return
    }
    
    // don't search again if the text is the same
    if let currentTerm = currentTerm, text == currentTerm {
      return
    }
    
    // handle history
    historyManager.add(item: HistoryItem(term: text, timestamp: Date().timeIntervalSince1970))
    historyUpdated()
    
    // reset some vals
    self.currentTerm = text
    self.footerState = .loading
    self.images = []
    self.resultsUpdated(text)
    
    imgurManager.findImages(with: text) { (images) in
      if let images = images {
        self.footerState = images.isEmpty ? .empty(text) : .results
        self.images = images
        self.currentPage = 1
        self.resultsUpdated(self.currentTerm!)
      }
    }
    
  }

  /// Fetches the images for the next page for the current search term
  func fetchNextPage() {
    
    // if there are no more results do not attemp to get more pages
    switch footerState {
    case .empty(_):
      return
    default: break
    }
    
    imgurManager.findImages(with: currentTerm ?? "", page: currentPage+1) { (images) in
      if let images = images {
        self.footerState = images.isEmpty ? .empty(self.currentTerm!) : .results
        self.images! += images
        self.currentPage += 1
        self.resultsUpdated(self.currentTerm!)
      }
    }
  }

  /// Gets the thumbnail link for the item at the specifed indexPath
  func thumbnail(for indexPath: IndexPath) -> URL? {
    guard let images = images, indexPath.row < images.count else { return nil }
    return URL(string: images[indexPath.row].thumbnail)
  }
  
  func imageLink(for indexPath: IndexPath) -> String? {
    guard let images = images, indexPath.row < images.count else { return nil }
    return images[indexPath.row].link
  }
  
  /// Returns the numbers of results for the current term
  func numberOfImages() -> Int {
    return images?.count ?? 0
  }
  
  func clearResults() {
    images = []
    footerState = .typing
    resultsUpdated("")
  }
  
  //MARK: TableView datasource
  func historyText(at indexPath: IndexPath) -> String {
    return historyManager.history[indexPath.row].term
  }
  
  func numberOfHistoryItems() -> Int {
    return historyManager.history.count
  }
  
}

