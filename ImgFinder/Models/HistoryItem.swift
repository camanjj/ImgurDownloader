//
//  HistoryItem.swift
//  ImgFinder
//
//  Created by Cameron Jackson on 2/4/18.
//  Copyright © 2018 Cameron Jackson. All rights reserved.
//

import Foundation
struct HistoryItem: Codable, Hashable {
  
  var term: String
  var timestamp: TimeInterval

  var hashValue: Int {
    return term.lowercased().hashValue
  }
  
}


func ==(lhs: HistoryItem, rhs: HistoryItem) -> Bool {
  return lhs.term.lowercased() == rhs.term.lowercased()
}

