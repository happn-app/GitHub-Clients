/*
 * GistsListViewController.swift
 * GitHub iOS
 *
 * Created by François Lamboley on 05/08/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation
import UIKit

import CollectionLoader_RESTCoreData

import GitHubBridge



class GistsListViewController: GitHubListViewController<Gist> {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		cellIdentifier = "GistCell"
		
		let t = title
		title = nil; title = t
	}
	
	override var shouldShowSearchBar: Bool {
		return false /* Gists searching is apparently not supported by the GitHub API */
	}
	
	override var numberOfElementsPerPage: Int {
		return 75
	}
	
	override func configureCell(_ cell: UITableViewCell, element: Gist) {
		cell.textLabel?.text = element.firstFileName
	}
	
	override func collectionLoaderHelper(for searchText: String?, context: NSManagedObjectContext) -> CoreDataSearchCLH<Gist, GitHubBMOBridge, GitHubPageInfoRetriever> {
		assert(searchText == nil)
		
		let fetchRequest: NSFetchRequest<Gist> = Gist.fetchRequest()
		let deletionDateProperty = Gist.entity().attributesByName[#keyPath(Gist.zDeletionDateInGistList)]!
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Gist.creationDate), ascending: false)]
		return CoreDataSearchCLH(fetchRequest: fetchRequest, additionalFetchInfo: nil, deletionDateProperty: deletionDateProperty, context: AppDelegate.shared.context, pageInfoRetriever: AppDelegate.shared.pageInfoRetriever, requestManager: AppDelegate.shared.requestManager)
	}
	
}
