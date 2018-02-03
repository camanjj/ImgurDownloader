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
  var imageCache = [String: UIImage]()
  var fetching = Set<String>()
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
  
  func fetchImage(with link: String, _ indexPath: IndexPath, _ imageView: UIImageView? = nil) {
    
    // if we are already fetching for this link do nothing else
    if fetching.contains(link) {
      return
    }
    
    fetching.insert(link)
    
    let session = URLSession.shared
    
    guard let url = URL(string: link) else {
      return
    }
    
    session.dataTask(with: url) { (data, _, error) in
      
      if let error = error {
        print("Error fetching image: \(error)")
        return
      }
      
      DispatchQueue.main.async {
        
        // make sure we can make an image from the data
        guard let data = data, let image = UIImage(data: data) else {
          return
        }
        
        // add the image to the cache
        self.imageCache[link] = image
        
//        imageView.image = image
        
        // if the cell is visible, show the image and stop the indicator
        if let cell = self.imagesController?.collectionView?.cellForItem(at: indexPath) as? ImageCell {
          cell.activityView.stopAnimating()
          cell.imageView.image = image
          cell.contentView.layoutIfNeeded()
        }
      }
      
      
    }.resume()
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    
    // clear out the image cache if we recieved a memory warning
    imageCache = [String:UIImage]()
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
    cell.imageView.kf.setImage(with: ImageResource(downloadURL: URL(string: link)))
    
    // load the image if cached, otherwise fetch it
    if let image = imageCache[link] {
      cell.activityView.stopAnimating()
      cell.imageView.image = image
    } else {
      cell.activityView.startAnimating()
      cell.imageView.image = nil
      fetchImage(with: link, indexPath, cell.imageView)
    }
    
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
    
    let cell = cell as! ImageCell
    let link = images[indexPath.row].thumbnail
    
    // load the image if cached, otherwise fetch it
    if let image = imageCache[link] {
      cell.activityView.stopAnimating()
      cell.imageView.image = image
    } else {
      cell.activityView.startAnimating()
      cell.imageView.image = nil
      fetchImage(with: link, indexPath, cell.imageView)
    }
    
    if indexPath.row == images.count-1 {
      // TODO: load more rows
      print("At end")
    }
    
  }

}

extension ViewController: UICollectionViewDataSourcePrefetching {
  func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    
    indexPaths.forEach {
      let link = images[$0.row].thumbnail
      fetchImage(with: link, $0)
    }
    
  }
  
  
}
