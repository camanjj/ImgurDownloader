//
//  HistoryManager.swift
//  ImgFinder
//
//  Created by Cameron Jackson on 2/4/18.
//  Copyright © 2018 Cameron Jackson. All rights reserved.
//

import Foundation

class HistoryManager {
  
  private let maxHistory = 50
  private let fileName = "history.json"
  private let fileManager = FileManager.default
  
  var history = NSMutableOrderedSet(capacity: 20)
  
  init() {
    // attempt to load the previous history items from json file
    if let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
      
      let url = directory.appendingPathComponent(fileName)
      
      do {
        let data = try Data(contentsOf: url)
        var historyArray: [HistoryItem] = try JSONDecoder().decode([HistoryItem].self, from: data)
        
        // sort the history
        historyArray = historyArray.sorted { item1, item2 in return item1.timestamp > item2.timestamp }
        
        // add the hisrory to the set
        history.addObjects(from: historyArray)
        
      } catch {
        print("Error reading history from file")
      }
      
    }
  }
  
  func add(item: HistoryItem) {
    
    // remove the item if the term already exist in the history
    if history.contains(item) {
      history.remove(item)
    }
    
    // limit the size of the history to 50 items
    if history.count == maxHistory {
      history.removeObject(at: maxHistory-1) // remove last history item
    }
    
    history.insert(item, at: 0) // always add the new item to the beginning of the list
    saveHistory()
  }
  
  func remove(at index: Int) {
    if index < history.count {
      history.removeObject(at: index)
      saveHistory()
    }
  }
  
  /// saves the history to a file
  private func saveHistory() {
    let historyArr = history.map({ $0 as! HistoryItem })
    
    if let jsonData = try? JSONEncoder().encode(historyArr), let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
      
      let url = directory.appendingPathComponent(fileName)
      
      do {
        try jsonData.write(to: url)
      } catch {
        print("Failed to save the history")
      }
    }
  }
  
}
