/*
 * GitHubListViewController.swift
 * GitHub iOS
 *
 * Created by François Lamboley on 14/07/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation
import UIKit

import GitHubBridge
import CollectionAndTableViewUpdateConveniences
import CollectionLoader
import CollectionLoader_RESTCoreData



class GitHubListViewController<ListElement : NSManagedObject> : UITableViewController, NSFetchedResultsControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
	
	var cellIdentifier: String!
	
	private(set) var collectionLoader: CollectionLoader<CoreDataSearchCLH<ListElement, GitHubBMOBridge, GitHubPageInfoRetriever>>!
	private(set) var searchController: UISearchController!
	
	var resultsController: NSFetchedResultsController<ListElement> {
		return collectionLoader.helper.resultsController
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		/* ***** Configuring the Table View ***** */
		tableView.fetchedResultsControllerMoveMode = .move(reloadMode: .standard)
		tableView.fetchedResultsControllerReloadMode = .handler{ [weak self] cell, object, _, _ in self?.configureCell(cell, element: object as! ListElement) }
		
		/* ***** Add refresh control to the table view ***** */
		let rc = UIRefreshControl()
		rc.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
		tableView.refreshControl = rc
		
		/* ***** Configuring the Search Controller ***** */
		if shouldShowSearchBar {
			searchController = UISearchController(searchResultsController: nil)
			searchController.delegate = self
			searchController.searchResultsUpdater = self
			searchController.hidesNavigationBarDuringPresentation = true
			searchController.obscuresBackgroundDuringPresentation = false
			
			navigationItem.searchController = searchController
			definesPresentationContext = true /* Needed so that navigation works when searching */
		}
		
		/* ***** Setup the Collection Loader ***** */
		setupCollectionLoader(searchText: nil)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		/* If the refresh control is updated too soon, the collection view inset
		 * will not be updated and we won't be able to show the refresh control.
		 * So we have to block the update until the view _will_ appear. */
		blockSetRefreshControlIsRefreshing = false
		collectionLoaderIsLoadingFirstPageChangedHandler()
	}
	
	/* ***********************
      MARK: - Override Points
	   *********************** */
	
	var shouldShowSearchBar: Bool {
		return true
	}
	
	var numberOfElementsPerPage: Int {
		return 21
	}
	
	func configureCell(_ cell: UITableViewCell, element: ListElement) {
		fatalError("Abstract method called.")
	}
	
	func collectionLoaderHelper(for searchText: String?, context: NSManagedObjectContext) -> CoreDataSearchCLH<ListElement, GitHubBMOBridge, GitHubPageInfoRetriever> {
		fatalError("Abstract method called.")
	}
	
	/* ******************************************
      MARK: - Table View DataSource and Delegate
	   ****************************************** */
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return resultsController.sections!.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return resultsController.sections![section].numberOfObjects
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
		configureCell(cell, element: resultsController.object(at: indexPath))
		return cell
	}
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if indexPath.section == tableView.numberOfSections-1 && indexPath.row >= tableView.numberOfRows(inSection: indexPath.section)-5 {
			collectionLoader.loadNextPage()
		}
	}
	
	/* *******************************
      MARK: - Search Results Updating
	   ******************************* */
	
	func updateSearchResults(for searchController: UISearchController) {
		timerRefreshCollectionLoader?.invalidate()
		timerRefreshCollectionLoader = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
			self.timerRefreshCollectionLoader = nil
			self.setupCollectionLoader(searchText: searchController.searchBar.text)
		})
	}
	
	/* ******************************************
      MARK: - NSFetchedResultsControllerDelegate
      ****************************************** */
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.fetchedResultsControllerWillChangeContent()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		tableView.fetchedResultsControllerDidChange(section: sectionInfo, atIndex: sectionIndex, forChangeType: type)
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		tableView.fetchedResultsControllerDidChange(object: anObject, atIndexPath: indexPath, forChangeType: type, newIndexPath: newIndexPath)
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.fetchedResultsControllerDidChangeContent()
	}
	
	/* ***************
      MARK: - Private
	   *************** */
	
	private var blockSetRefreshControlIsRefreshing = true
	
	private var timerRefreshCollectionLoader: Timer?
	
	private func setupCollectionLoader(searchText: String?) {
		collectionLoader?.cancelAllLoadings()
		collectionLoader?.helper.resultsController.delegate = nil
		
		let clh = collectionLoaderHelper(for: searchText, context: AppDelegate.shared.context)
		collectionLoader = CollectionLoader(collectionLoaderHelper: clh, numberOfElementsPerPage: numberOfElementsPerPage)
		collectionLoader.isLoadingFirstPageChangedHandler = { [weak self] in self?.collectionLoaderIsLoadingFirstPageChangedHandler() }
		collectionLoader.helper.resultsController.delegate = self
		collectionLoader.loadFirstPage()
		
		tableView.reloadData()
	}
	
	private func collectionLoaderIsLoadingFirstPageChangedHandler() {
		guard !blockSetRefreshControlIsRefreshing, let refreshControl = refreshControl else {return}
		
		let isLoading = collectionLoader.isLoadingFirstPage
		guard isLoading != refreshControl.isRefreshing else {return}
		if !isLoading {refreshControl.endRefreshing()}
		else          {refreshControl.beginRefreshing()}
	}
	
	@objc
	@IBAction func refreshTableView(_ sender: AnyObject) {
		collectionLoader.loadFirstPage()
	}
	
}
