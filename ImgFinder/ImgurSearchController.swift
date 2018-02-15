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
  
  let viewModel: ImgurSearchViewModel
  let downloader = ImageDownloader()
  
  
  required init?(coder aDecoder: NSCoder) {
    let delegate = UIApplication.shared.delegate! as! AppDelegate
    viewModel = ImgurSearchViewModel(dataContext: delegate.persistentContainer.viewContext)
    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    searchButton.titleLabel?.numberOfLines = 0
    searchButton.titleLabel?.textAlignment = .center
    
    configureCollectionView()
    configureSearchController()
    configureTableView()
    
    self.definesPresentationContext = true
    
    // keep track when the search results have changed
    viewModel.resultsUpdated = { [unowned self] term, _ in
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
  
  /// create and config the collection view for the images
  func configureCollectionView() {
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
  
  
  /// Fetches an image from cache or web for a imageView at an indexPath
  func fetchImage(with link: String, _ indexPath: IndexPath, _ imageView: UIImageView) {
    
    // check if the image is cached
    if ImageCache.default.imageCachedType(forKey: link).cached {
      ImageCache.default.retrieveImage(forKey: link, options: nil) {
        image, cacheType in
          imageView.image = image
      }
      return
    }
    
    // if we are already fetching for this link do nothing else
    if viewModel.fetching.contains(link) {
      return
    }
    
    viewModel.fetching.insert(link)
    
    let session = URLSession.shared
    
    guard let url = URL(string: link) else {
      return
    }
    
    downloader.downloadImage(url: url, imageView: imageView)
    
//    session.dataTask(with: url) { (data, _, error) in
//
//      if let error = error {
//        print("Error fetching image: \(error)")
//        return
//      }
//
//      DispatchQueue.main.async {
//
//        // make sure we can make an image from the data
//        guard let data = data, let image = UIImage(data: data) else {
//          return
//        }
//
//        // save image in cache
//        ImageCache.default.store(image, forKey: link)
//        imageView.image = image
//
//        // stop the activity indicator in the cell
//        if let contentView = imageView.superview, let activityView = contentView.subviews.last as? UIActivityIndicatorView {
//          activityView.stopAnimating()
//        }
//      }
//
//    }.resume()
    
  }

  
  /// configure the search controller
  func configureSearchController() {
    searchController = UISearchController(searchResultsController: imagesController)
    searchController?.searchBar.placeholder = "Search for images"
    searchController?.hidesNavigationBarDuringPresentation = false
    navigationItem.titleView = searchController?.searchBar
    searchController?.searchBar.delegate = self
    searchController?.searchResultsUpdater = self
    searchController?.searchBar.returnKeyType = .done
  }
  
  /// configure the history table view
  func configureTableView() {
    historyTableView.dataSource = self
    historyTableView.delegate = self
    historyTableView.allowsSelectionDuringEditing = false
    let footerLabel = UILabel()
    footerLabel.textAlignment = .center
    footerLabel.text = "\nSwipe left to delete previous search entry"
    footerLabel.numberOfLines = 0
    footerLabel.textColor = .lightGray
    footerLabel.font = UIFont.systemFont(ofSize: 12)
    historyTableView.tableFooterView = footerLabel
    footerLabel.sizeToFit()
  }
  
  /// show/hide the table view based on the history
  func toggleTableView() {
    if viewModel.numberOfHistoryItems() == 0 {
      historyTableView.isHidden = true
    } else {
      historyTableView.isHidden = false
    }
  }

  @objc func startSearch() {
    viewModel.findImages(for: searchController?.searchBar.text)
  }
  
  @IBAction func getStartedClick(_ sender: Any) {
    searchController?.searchBar.becomeFirstResponder()
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
      
      if !ImageCache.default.imageCachedType(forKey: link.absoluteString).cached {
        cell.imageView.image = nil
        cell.activityView.startAnimating()
      }
      
      fetchImage(with: link.absoluteString, indexPath, cell.imageView)
//      cell.imageView.kf.setImage(with: ImageResource(downloadURL: link))
    }
    
    return cell
    
  }
  
  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    
    let view: SearchFooterView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footer", for: indexPath) as! SearchFooterView
    
    // configure the footer based on the state
    switch viewModel.footerState {
    case .typing:
      view.label.isHidden = true
      view.activityView.startAnimating()
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

extension ImgurSearchController: UICollectionViewDelegate {
  
  
  
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
    // load more rows when we get to the 15th last row
    if indexPath.row == viewModel.numberOfImages() - 15 {
      viewModel.fetchNextPage()
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    // add search term b/c we clicked on something
    viewModel.addTextToHistory(searchController!.searchBar.text!)
    
    
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
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
    if scrollView != historyTableView {
      // we are in the collection view
      
      if viewModel.numberOfImages() > 0 {
        // add history item when scrolling
        viewModel.addTextToHistory(searchController!.searchBar.text!)
      }
      
    }
    
  }
}

extension ImgurSearchController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    
    // don't update anything if the text has not changed from the last request
    if !viewModel.shouldRefresh(searchController.searchBar.text) {
      return
    }
    
    // allows for realtime searching
    viewModel.clearResults()
    
    viewModel.findImages(for: searchController.searchBar.text)
  }
}

extension ImgurSearchController: UISearchBarDelegate {
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    viewModel.clearResults()
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
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return viewModel.numberOfHistoryItems() == 0 ? nil : "Search History"
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    // load the text from the history item and search for it
    let text = viewModel.historyText(at: indexPath)
    searchController?.searchBar.becomeFirstResponder()
    searchController?.searchBar.text = text
    viewModel.addTextToHistory(text)
    
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    
    // add the action to delete the speciic history item
    let removeAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
      self.viewModel.removeHistoryItem(at: indexPath)
      tableView.deleteRows(at: [indexPath], with: .automatic)
      self.toggleTableView()
    }
    return [removeAction]
  }
  
}
