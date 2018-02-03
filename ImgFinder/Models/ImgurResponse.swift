//
//  ImgurResponse.swift
//  ImgFinder
//
//  Created by Cameron Jackson on 2/2/18.
//  Copyright © 2018 Cameron Jackson. All rights reserved.
//

import Foundation

struct ImgurResponse: Codable {
  
  var data: [Gallery]?
  var status: Int
  var success: Bool
  
}
