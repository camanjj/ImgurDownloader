//
//  ImageDownloader.swift
//  ImgFinder
//
//  Created by Cameron Jackson on 2/15/18.
//  Copyright © 2018 Cameron Jackson. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher


class ImageDownloader {
  
  struct Download {
    var link: String
    var imageView: UIImageView
  }
  
  var currentTask = [UIImageView: URLSessionDataTask]()
  
  let session = URLSession.shared
  
  func downloadImage(url: URL, imageView: UIImageView) {
    
    // check if there is a task for the imageview already
    if let oldTask = currentTask[imageView] {
      oldTask.cancel()
    }
    
    // create a new task for that imageView
    let task = session.dataTask(with: url) { (data, _, error) in
      
      if let error = error {
        print("Error fetching image: \(error)")
        return
      }
      
      DispatchQueue.main.async {
        
        // make sure we can make an image from the data
        guard let data = data, let image = UIImage(data: data) else {
          return
        }
        
        // save image in cache
        ImageCache.default.store(image, forKey: url.absoluteString)
        imageView.image = image
        
        // stop the activity indicator in the cell
        if let contentView = imageView.superview, let activityView = contentView.subviews.last as? UIActivityIndicatorView {
          activityView.stopAnimating()
        }
      }
      
      }
    
    currentTask[imageView] = task
    task.resume()
    
  }
  
  
}
