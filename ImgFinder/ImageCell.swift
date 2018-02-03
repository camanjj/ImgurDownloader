//
//  ImageCell.swift
//  ImgFinder
//
//  Created by Cameron Jackson on 2/2/18.
//  Copyright © 2018 Cameron Jackson. All rights reserved.
//

import UIKit

class ImageCell: UICollectionViewCell {
  
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var activityView: UIActivityIndicatorView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.image = nil
  }
  
}
