//
//  ViewController.swift
//  ImgFinder
//
//  Created by Cameron Jackson on 2/2/18.
//  Copyright © 2018 Cameron Jackson. All rights reserved.
//

import UIKit
import Kingfisher
import SKPhotoBrowser

class ImgurSearchController: UIViewController {

  @IBOutlet weak var historyTableView: UITableView!
  @IBOutlet weak var searchButton: UIButton!
  var searchController: UISearchController?
  var imagesController: UICollectionViewController?
  let cellId = "ImageCell"
  let historyId = "HistoryCell"
  
  let viewModel = ImgurSearchViewModel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    searchButton.titleLabel?.numberOfLines = 0
    searchButton.titleLabel?.textAlignment = .center
    
    configureCollectionView()
    configureSearchController()
    configureTableView()
    
    self.definesPresentationContext = true
    
    // keep track when the search results have changed
    viewModel.resultsUpdated = { [unowned self] term in
      self.imagesController?.collectionView?.reloadData()
    }
    
    // keep track when the history has been changed
    viewModel.historyUpdated = { [unowned self] in
      self.toggleTableView()
      self.historyTableView.reloadData()
    }
    
    // decide to show or hide the table view
    toggleTableView()
  }
  
  func configureCollectionView() {
    // create and config the collection view for the images
    let collectionViewLayout = UICollectionViewFlowLayout()
    imagesController = UICollectionViewController(collectionViewLayout: collectionViewLayout)
    imagesController?.collectionView?.backgroundColor = .black
    imagesController?.collectionView?.dataSource = self
    imagesController?.collectionView?.delegate = self
    
    // register the cells/views for the collection view
    let nib = UINib(nibName: "ImageCell", bundle: nil)
    imagesController?.collectionView?.register(nib, forCellWithReuseIdentifier: cellId)
    
    let footerNib = UINib(nibName: "SearchFooterView", bundle: nil)
    imagesController?.collectionView?.register(footerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "footer")
  }
  
  func configureSearchController() {
    // configure the search controller
    searchController = UISearchController(searchResultsController: imagesController)
    //    searchController?.searchResultsUpdater = self // only pay attention to when the search button is selected
    searchController?.searchBar.placeholder = "Search for images"
    searchController?.hidesNavigationBarDuringPresentation = false
    navigationItem.titleView = searchController?.searchBar
    searchController?.searchBar.delegate = self
  }
  
  func configureTableView() {
    historyTableView.dataSource = self
    historyTableView.delegate = self
  }
  
  func toggleTableView() {
    if viewModel.numberOfHistoryItems() == 0 {
      historyTableView.isHidden = true
    } else {
      historyTableView.isHidden = false
    }
  }
  
  @IBAction func getStartedClick(_ sender: Any) {
    searchController?.searchBar.becomeFirstResponder()
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
    
    // configure the footer based on the state
    switch viewModel.footerState {
    case .typing:
      view.label.isHidden = false
      view.label.text = "Click Search to find images"
      view.activityView.stopAnimating()
    case .loading, .results:
      view.label.isHidden = true
      view.activityView.startAnimating()
    case .empty(let term):
      view.label.text = "No more results for \(term)"
      view.label.isHidden = false
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
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    // present the image for panning and zooming
    guard let link = viewModel.imageLink(for: indexPath) else { return }
    let cell = collectionView.cellForItem(at: indexPath) as! ImageCell
    let photo = SKPhoto.photoWithImageURL(link)
    
    // workaround for the issue of having a nil imageView.image b/c ?? UIImage() caused crash
    let browser: SKPhotoBrowser
    if let originImage = cell.imageView.image {
        browser = SKPhotoBrowser(originImage: originImage, photos: [photo], animatedFromView: cell)
    } else {
      browser = SKPhotoBrowser(photos: [photo])
    }
    
    browser.initializePageIndex(0)
    present(browser, animated: true, completion: {})
    
  }
}

extension ImgurSearchController: UISearchBarDelegate {
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    viewModel.findImages(for: searchBar.text)
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    
  }
}

extension ImgurSearchController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.numberOfHistoryItems()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    var cell = tableView.dequeueReusableCell(withIdentifier: historyId)
    if cell == nil {
      cell = UITableViewCell(style: .default, reuseIdentifier: historyId)
    }
    
    cell?.textLabel?.text = viewModel.historyText(at: indexPath)
    
    return cell!
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    // load the text from the history item and search for it
    let text = viewModel.historyText(at: indexPath)
    searchController?.searchBar.becomeFirstResponder()
    searchController?.searchBar.text = text
    viewModel.findImages(for: text)
  }
  
}
