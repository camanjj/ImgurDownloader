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
    
    // register the cells
    let nib = UINib(nibName: "ImageCell", bundle: nil)
    imagesController.collectionView?.register(nib, forCellWithReuseIdentifier: cellId)
    
    let footerNib = UINib(nibName: "SearchFooterView", bundle: nil)
    imagesController.collectionView?.register(footerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "footer")
    
    self.imagesController = imagesController
    
    // configure the search controller
    searchController = UISearchController(searchResultsController: imagesController)
//    searchController?.searchResultsUpdater = self
    searchController?.searchBar.placeholder = "Search for images"
    searchController?.hidesNavigationBarDuringPresentation = false
    navigationItem.titleView = searchController?.searchBar
    searchController?.searchBar.delegate = self
    
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
    if let link = viewModel.thumbnail(for: indexPath) {
      cell.imageView.kf.setImage(with: ImageResource(downloadURL: link))
    }
    
    return cell
    
  }
  
  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    
    let view: SearchFooterView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footer", for: indexPath) as! SearchFooterView
    
    // configure the footer based on if there are more results or not
    switch viewModel.footerState {
    case .typing:
      view.label.isHidden = true
      view.activityView.stopAnimating()
    case .loading, .results:
      view.label.isHidden = true
      view.activityView.startAnimating()
    case .empty(let term):
      view.label.text = "No more results for \(term)"
      view.activityView.stopAnimating()
      
    }

    return view
    
  }
}

extension ImgurSearchController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let size = ((collectionView.frame.width-20) / 3)
    return CGSize(width: size, height: size)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
    return CGSize(width: collectionView.frame.width, height: 80)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets.zero
  }
  
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    // load more rows when we get to the last row
    if indexPath.row == viewModel.numberOfImages() - 1 {
      viewModel.fetchNextPage()
    }
  }
}

extension ImgurSearchController: UISearchBarDelegate {
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    viewModel.findImages(for: searchBar.text)
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    
  }
}
