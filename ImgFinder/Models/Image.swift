//
//  Image.swift
//  ImgFinder
//
//  Created by Cameron Jackson on 2/2/18.
//  Copyright © 2018 Cameron Jackson. All rights reserved.
//

import Foundation

struct Image: Codable {
  
  var id: String
  var title: String?
  var description: String?
  var link: String
  var thumbnail: String

  enum CodingKeys: String, CodingKey {
    case id, title, description, link
  }
  
  // decoder for json that transforms and sets the thumnail
  init(from decoder: Decoder) throws {
    let json = try decoder.container(keyedBy: CodingKeys.self)
    id = try json.decode(String.self, forKey: .id)
    title = try json.decodeIfPresent(String.self, forKey: .title)
    description = try json.decodeIfPresent(String.self, forKey: .description)
    link = try json.decode(String.self, forKey: .link)
    
    thumbnail = "https://i.imgur.com/\(id)m.\((link as NSString).pathExtension)"
    
  }
  
}


struct Gallery: Codable {
  
  var id: String
  var title: String
  var description: String?
  var link: String
  var images: [Image]?
  
}
