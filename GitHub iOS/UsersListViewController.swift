/*
 * UsersListViewController.swift
 * GitHub iOS
 *
 * Created by François Lamboley on 09/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation
import UIKit

import BMO
import BMO_RESTCoreData
import CollectionAndTableViewUpdateConveniences
import CollectionLoader
import CollectionLoader_RESTCoreData
import GitHubBridge
import RESTUtils



class UsersListViewController : UITableViewController, NSFetchedResultsControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let t = title
		title = nil; title = t
		
		/* ***** Configuring the Table View ***** */
		tableView.fetchedResultsControllerMoveMode = .move(reloadMode: .standard)
		tableView.fetchedResultsControllerReloadMode = .handler{ [weak self] cell, object, _, _ in self?.configureCell(cell, user: object as! User) }
		
		/* ***** Configuring the Search Controller ***** */
		searchController = UISearchController(searchResultsController: nil)
		searchController.delegate = self
		searchController.searchResultsUpdater = self
		searchController.hidesNavigationBarDuringPresentation = true
		searchController.obscuresBackgroundDuringPresentation = false
		
		navigationItem.searchController = searchController
		
		/* ***** Setup the Collection Loader ***** */
		let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.remoteId), ascending: true)]
		let collectionLoaderHelper: CoreDataSearchCLH<User, GitHubBMOBridge, GitHubPageInfoRetriever> = CoreDataSearchCLH(fetchRequest: fetchRequest, additionalFetchInfo: nil, deletionDateProperty: User.entity().attributesByName[#keyPath(User.zDeletionDateInUsersList)]!, context: AppDelegate.shared.context, pageInfoRetriever: AppDelegate.shared.pageInfoRetriever, requestManager: AppDelegate.shared.requestManager)
		collectionLoader = CollectionLoader(collectionLoaderHelper: collectionLoaderHelper, numberOfElementsPerPage: 21)
		collectionLoader.helper.resultsController.delegate = self
		collectionLoader.loadFirstPage()
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return resultsController.sections!.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return resultsController.sections![section].numberOfObjects
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
		configureCell(cell, user: resultsController.object(at: indexPath))
		return cell
	}
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if indexPath.section == tableView.numberOfSections-1 && indexPath.row >= tableView.numberOfRows(inSection: indexPath.section)*6/7 {
			collectionLoader.loadNextPage()
		}
	}
	
	/* *******************************
      MARK: - Search Results Updating
	   ******************************* */
	
	func updateSearchResults(for searchController: UISearchController) {
		print(searchController.searchBar.text!)
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
	
	private var collectionLoader: CollectionLoader<CoreDataSearchCLH<User, GitHubBMOBridge, GitHubPageInfoRetriever>>!
	private var searchController: UISearchController!
	
	private var resultsController: NSFetchedResultsController<User> {
		return collectionLoader.helper.resultsController
	}
	
	private func configureCell(_ cell: UITableViewCell, user: User) {
		cell.textLabel?.text = user.username
	}
	
}
