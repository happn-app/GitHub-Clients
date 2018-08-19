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
	
	enum GistsSource {
		
		case all
		case gists(of: User)
		
	}
	
	var gistsSource = GistsSource.all
	
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
		
		let gistEntity = Gist.entity()
		let ephemeralDeletionDateProperty = gistEntity.attributesByName[#keyPath(Gist.zEphemeralDeletionDate)]!
		
		let deletionDateProperty: NSAttributeDescription
		switch gistsSource {
		case .all:
			deletionDateProperty = gistEntity.attributesByName[#keyPath(Gist.zDeletionDateInGistList)]!
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Gist.creationDate), ascending: false)]
			
		case .gists(of: let user):
			nullify(property: ephemeralDeletionDateProperty, inInstancesOf: gistEntity, context: AppDelegate.shared.context)
			deletionDateProperty = ephemeralDeletionDateProperty
			fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Gist.owner), user)
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Gist.creationDate), ascending: false)]
		}
		return CoreDataSearchCLH(fetchRequest: fetchRequest, additionalFetchInfo: nil, deletionDateProperty: deletionDateProperty, context: AppDelegate.shared.context, pageInfoRetriever: AppDelegate.shared.pageInfoRetriever, requestManager: AppDelegate.shared.requestManager)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "ShowGist" else {return}
		guard let selectedRow = (sender as? UITableViewCell).flatMap({ tableView.indexPath(for: $0) }) else {return}
		
		let destinationVC = segue.destination as! GistViewController
		destinationVC.gist = resultsController.object(at: selectedRow)
	}
	
}
