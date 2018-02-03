//
//  ViewController.swift
//  ImgFinder
//
//  Created by Cameron Jackson on 2/2/18.
//  Copyright © 2018 Cameron Jackson. All rights reserved.
//

import UIKit
import Kingfisher

class ViewController: UIViewController {

  @IBOutlet weak var searchButton: UIButton!
  var searchController: UISearchController?
  var imagesController: UICollectionViewController?
  let cellId = "ImageCell"
  
  // cache used to store the images in memory
  var images = [Image]()
  var currentSearchTerm: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // create and config the collection view for the images
    let collectionViewLayout = UICollectionViewFlowLayout()
    let imagesController = UICollectionViewController(collectionViewLayout: collectionViewLayout)
    imagesController.collectionView?.backgroundColor = .white
    imagesController.collectionView?.dataSource = self
    imagesController.collectionView?.delegate = self
//    imagesController.collectionView?.prefetchDataSource = self
    
    let nib = UINib(nibName: "ImageCell", bundle: nil)
    imagesController.collectionView?.register(nib, forCellWithReuseIdentifier: cellId)
    
    self.imagesController = imagesController
    
    // configure the search controller
    searchController = UISearchController(searchResultsController: imagesController)
    searchController?.searchResultsUpdater = self
    searchController?.searchBar.placeholder = "Search for images"
    searchController?.hidesNavigationBarDuringPresentation = false
    navigationItem.titleView = searchController?.searchBar
    
    self.definesPresentationContext = true
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

}

extension ViewController: UISearchResultsUpdating {
  
  func updateSearchResults(for searchController: UISearchController) {
    
    // only automatic search when there are more than 3 characters in the searchbar
    guard let text = searchController.searchBar.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), text.count > 3 else {
      return
    }
    
    // don't search again if the text is the same
    if let curTerm = currentSearchTerm, text == curTerm {
      return
    }
    
    currentSearchTerm = text
    
    // TODO: search with the text
    ImgManager.shared.findImages(with: text) { [unowned self] (images) in
      if let images = images {
        self.images = images
        DispatchQueue.main.async {
            self.imagesController?.collectionView?.reloadData()
        }
        
      }
    }
    
  }
  
}

extension ViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return images.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ImageCell
    
    let link = images[indexPath.row].thumbnail
    cell.imageView.kf.indicatorType = .activity
    cell.imageView.kf.setImage(with: ImageResource(downloadURL: URL(string: link)!))
    
    return cell
    
  }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let size = ((collectionView.frame.width-20) / 3)
    return CGSize(width: size, height: size)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets.zero
  }
  
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    if indexPath.row == images.count-1 {
      // TODO: load more rows
      print("At end")
    }
    
  }
}
