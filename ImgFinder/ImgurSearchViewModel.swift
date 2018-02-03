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

class ImgurSearchViewModel {
  private var images: [Image]?
  private var currentPage = 1
  private var currentTerm: String?
  
  var resultsUpdated: ((String) -> ()) = { _ in }
  
  func findImages(for text: String?) {
    
    // only automatic search when there are more than 3 characters in the searchbar
    guard let text = text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), text.count > 3 else {
      return
    }
    
    // don't search again if the text is the same
    if let currentTerm = currentTerm, text == currentTerm {
      return
    }
    
    currentTerm = text
    
    ImgManager.shared.findImages(with: text) { (images) in
      if let images = images {
        
        DispatchQueue.main.async {
          self.images = images
          self.currentPage = 1
          self.resultsUpdated(self.currentTerm!)
//          self.delegate?.fetched(images: images, for: self.currentTerm!)
        }
        
      }
    }
    
  }

  func fetchNextPage() {
    
    ImgManager.shared.findImages(with: currentTerm ?? "", page: currentPage+1) { (images) in
      if let images = images {
        DispatchQueue.main.async {
          self.images! += images
          self.currentPage += 1
          self.resultsUpdated(self.currentTerm!)
//          self.delegate?.fetched(images: self.images!, for: self.currentTerm!)
        }
        
      }
    }
  }

  func thumbnail(for indexPath: IndexPath) -> String? {
    guard let images = images, indexPath.row < images.count else { return nil }
    return images[indexPath.row].thumbnail
  }
  
  func numberOfImages() -> Int {
    return images?.count ?? 0
  }
}

