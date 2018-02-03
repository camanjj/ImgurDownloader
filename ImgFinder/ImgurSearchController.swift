//
//  ViewController.swift
//  ImgFinder
//
//  Created by Cameron Jackson on 2/2/18.
//  Copyright © 2018 Cameron Jackson. All rights reserved.
//

import UIKit
import Kingfisher

class ImgurSearchController: UIViewController {

  @IBOutlet weak var searchButton: UIButton!
  var searchController: UISearchController?
  var imagesController: UICollectionViewController?
  let cellId = "ImageCell"
  
  let viewModel = ImgurSearchViewModel()
  
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
    
    viewModel.resultsUpdated = { [unowned self] term in
      self.imagesController?.collectionView?.reloadData()
    }
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

}

extension ImgurSearchController: UISearchResultsUpdating {
  
  func updateSearchResults(for searchController: UISearchController) {
    viewModel.findImages(for: searchController.searchBar.text)
  }
}

extension ImgurSearchController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return viewModel.numberOfImages()
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ImageCell
    cell.imageView.kf.indicatorType = .activity
    
    // load the thumbnail if valid
    if let link = viewModel.thumbnail(for: indexPath), let url = URL(string: link) {
      cell.imageView.kf.setImage(with: ImageResource(downloadURL: url))
    }
    
    return cell
    
  }
}

extension ImgurSearchController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let size = ((collectionView.frame.width-20) / 3)
    return CGSize(width: size, height: size)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets.zero
  }
  
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    if indexPath.row == viewModel.numberOfImages() - 1 {
      // TODO: load more rows
      viewModel.fetchNextPage()
    }
    
  }
}
