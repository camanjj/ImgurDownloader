//
//  ImgurManager.swift
//  ImgFinder
//
//  Created by Cameron Jackson on 2/2/18.
//  Copyright © 2018 Cameron Jackson. All rights reserved.
//

import Foundation

enum Sort: String {
  case top, viral, time
}

enum Window: String {
  case all, day, week, month, year
}

/// Class that handles sendng request to the
class ImgManager {
  
  private let clientId = "0bcf852c1d22f46"
  private let baseSearchUrl = "https://api.imgur.com/3/gallery/search"
  private let session = URLSession.shared
  
  private var currentTask: URLSessionDataTask?
  
  static var shared = ImgManager()
  
  init() {  }
  
  func findImages(with term: String, sort: Sort = .top, window: Window = .all, page: Int = 1, callback: @escaping (([Image]?) -> ())) {
    
    // url encode the search term
    guard let escapedTerm = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
      callback(nil)
      return
    }
    
    // construct the complete url w/ default values
    let url = baseSearchUrl + "/\(sort.rawValue)/\(window.rawValue)/\(page)/?q=\(escapedTerm)"
    
    // create the requet and add the imgur Client ID to the authortization header
    var request = URLRequest(url: URL(string: url)!)
    request.addValue("Client-ID \(clientId)", forHTTPHeaderField: "Authorization")
    
    // stop the current task, if there is one
    if let _ = currentTask {
      currentTask?.cancel()
    }
    
    // handle task response
    currentTask = session.dataTask(with: request) { (data, response, error) in
      
      if let error = error {
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled {
          
        } else {
          
        }
        
        print("Problem with imgur request: \(error)")
        callback(nil)
        return
      }
      
      print(String(data: data!, encoding: .utf8)!)
      
      // parse and decode the json from the imgur response
      guard let data = data, let imgurResponse = try? JSONDecoder().decode(ImgurResponse.self, from: data), let galleries = imgurResponse.data else {
        print("Problem parsing the response")
        callback(nil)
        return
      }
      
      let images = galleries.reduce([Image](), { (r, gal) -> [Image] in
        return r + (gal.images ?? [])
      })
      
      callback(images)
      
    }
    
    currentTask?.resume()
    
  }
  
}
