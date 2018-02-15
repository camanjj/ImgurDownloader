//
//  HistoryManager.swift
//  ImgFinder
//
//  Created by Cameron Jackson on 2/4/18.
//  Copyright © 2018 Cameron Jackson. All rights reserved.
//

import Foundation
import CoreData

class HistoryManager {
  
  var historyEntity: NSEntityDescription
  var context: NSManagedObjectContext
  
  
  init(context: NSManagedObjectContext) {
    self.context = context
    self.context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    historyEntity = NSEntityDescription.entity(forEntityName: "HistoryItem", in: context)!
  }
  
  func add(term: String) {
    
    let item = NSManagedObject(entity: historyEntity, insertInto: context)
    
    item.setValue(term, forKey: "term")
    item.setValue(Date(), forKey: "timestamp")
    
    do {
      try context.save()
    } catch {
      print("Could not save. \(error.localizedDescription)")
    }
    
  }
  
  func remove(term: String) {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "HistoryItem")
    fetchRequest.predicate = NSPredicate(format: "term EQUALS %s", term)
    fetchRequest.fetchLimit = 1
    
    do {
      if let item = try context.fetch(fetchRequest).first as? HistoryItem {
        context.delete(item)
      }
    } catch {
      print("Could not delete. \(error.localizedDescription)")
    }
    
  }
  
  /// Gets all of the history sorted by the timestamp
  func getHistory() -> [HistoryItem] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "HistoryItem")
    fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "timestamp", ascending: false)]
    return try! context.fetch(fetchRequest) as! [HistoryItem]
  }
  
  
  /// Queries the history by a term
  func quertHistory(term: String) -> [HistoryItem] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "HistoryItem")
    fetchRequest.predicate = NSPredicate(format: "term CONTAINS %s", term)
    fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "timestamp", ascending: false)]
    return try! context.fetch(fetchRequest) as! [HistoryItem]
  }
  
}
