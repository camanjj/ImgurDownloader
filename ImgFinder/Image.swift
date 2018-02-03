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
  var title: String
  var description: String?
  var link: String
  var thumbnail: String?
  
}
