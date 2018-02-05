//
//  HistoryManager.swift
//  ImgFinder
//
//  Created by Cameron Jackson on 2/4/18.
//  Copyright © 2018 Cameron Jackson. All rights reserved.
//

import Foundation

class HistoryManager {
  
  private let fileName = "history.json"
  private let fileManager = FileManager.default
  var history = [HistoryItem]()
  
  init() {
    // attempt to load the previous history items from json file
    if let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
      
      let url = directory.appendingPathComponent(fileName)
      
      do {
        let data = try Data(contentsOf: url)
        history = try JSONDecoder().decode([HistoryItem].self, from: data)
        
        // sort the history
        history = history.sorted { item1, item2 in return item1.timestamp > item2.timestamp }
      } catch {
        print("Error reading history from file")
      }
      
    }
  }
  
  func add(item: HistoryItem) {
    history.insert(item, at: 0) // always add the new item to the beginning of the list
    saveHistory()
  }
  
  func remove(at index: Int) {
    if index < history.count {
      history.remove(at: index)
      saveHistory()
    }
  }
  
  /// saves the history to a file
  private func saveHistory() {
    if let jsonData = try? JSONEncoder().encode(history), let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
      
      let url = directory.appendingPathComponent(fileName)
      
      do {
        try jsonData.write(to: url)
      } catch {
        print("Failed to save the history")
      }
    }
  }
  
}
