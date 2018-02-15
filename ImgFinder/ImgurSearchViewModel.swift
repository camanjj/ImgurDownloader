//
//  File.swift
//  ImgFinder
//
//  Created by Cameron Jackson on 2/3/18.
//  Copyright © 2018 Cameron Jackson. All rights reserved.
//

import Foundation
import CoreData

enum FooterState {
  // note: typing is only used as an initial state
  case typing, loading, empty(String), results
}

class ImgurSearchViewModel {
  private var images: [Image]?
  private var currentPage = 1
  private var currentTerm: String?
  private var historyCache: [HistoryItem]?
  
  // managers
  private var imgurManager = ImgurManager()
  private var historyManager: HistoryManager
  
  var footerState: FooterState = .typing
  var resultsUpdated: ((String) -> ()) = { _ in } // search results update block
  var historyUpdated: (() -> ()) = { } // history update block
  
  
  init(dataContext: NSManagedObjectContext) {
    historyManager = HistoryManager(context: dataContext)
    historyCache = historyManager.getHistory()
  }
  
  /// Fetches the first page for the text given
  func findImages(for text: String?) {
    
    // only automatic search when there are more than 3 characters in the searchbar
    guard let text = text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), !text.isEmpty else {
      return
    }
    
    // don't search again if the text is the same
    if let currentTerm = currentTerm, text == currentTerm {
      return
    }
    
    // reset some vals
    self.currentTerm = text
    self.footerState = .loading
    self.images = []
    self.resultsUpdated(text)
    
    fetchImages(text, 1)
  }

  /// Fetches the images for the next page for the current search term
  func fetchNextPage() {
    
    // if there are no more results do not attempt to get more pages
    switch footerState {
    case .empty(_):
      return
    default: break
    }
    
    fetchImages(currentTerm ?? "", currentPage+1)
  }
  
  
  /// Handles sending the request to imgur
  private func fetchImages(_ text: String, _ page: Int) {
    
    imgurManager.findImages(with: text, page: page) { (result) in
      
      switch result {
      case .success(let images):
        self.footerState = images.isEmpty ? .empty(text) : .results
        self.currentPage = page
        
        self.addTextToHistory(text)
        
        // append or overwrite images based on if the call was for the first page
        if page == 1 {
          self.images = images
        } else {
          self.images = (self.images ?? []) + images
        }
        
        self.resultsUpdated(text)
      case .error:
        // add the search item to the history
        self.addTextToHistory(text)
      case .cancelled: break // don't add to history if the request was cancelled
      }
    }
    
  }
  
  /// Add an entry to the history
  func addTextToHistory(_ text: String) {
    // add the text to the history
    historyManager.add(term: text)
    historyCache = historyManager.getHistory()
    self.historyUpdated()
  }

  /// Gets the thumbnail link for the item at the specifed indexPath
  func thumbnail(for indexPath: IndexPath) -> URL? {
    guard let images = images, indexPath.row < images.count else { return nil }
    return URL(string: images[indexPath.row].thumbnail)
  }
  
  /// Gets the image link as a string for the specified indexPath
  func imageLink(for indexPath: IndexPath) -> String? {
    guard let images = images, indexPath.row < images.count else { return nil }
    return images[indexPath.row].link
  }
  
  /// Returns the numbers of results for the current term
  func numberOfImages() -> Int {
    return images?.count ?? 0
  }
  
  /// Clears the results and sets the footer state to typing
  func clearResults() {
    images = []
    footerState = .typing
    resultsUpdated("")
    currentTerm = nil
  }
  
  
  /// Method to check if the current search text is equal to the passed in search text
  func shouldRefresh(_ text: String?) -> Bool {
    return currentTerm != text
  }
  
  //MARK: TableView datasource
  func historyText(at indexPath: IndexPath) -> String {
    
    guard let historyCache = historyCache else {
      return ""
    }
    
    let item = historyCache[indexPath.row]
    return item.term ?? ""
  }
  
  func numberOfHistoryItems() -> Int {
    return historyCache?.count ?? 0
  }
  
  func removeHistoryItem(at indexPath: IndexPath) {
    
    guard let historyCache = historyCache else {
      return
    }
    
    historyManager.remove(term: historyCache[indexPath.row].term!)
  }
  
}
