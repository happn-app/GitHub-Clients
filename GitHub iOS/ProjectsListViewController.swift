/*
 * ProjectsListViewController.swift
 * GitHub iOS
 *
 * Created by François Lamboley on 14/07/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation
import UIKit

import CollectionLoader_RESTCoreData

import GitHubBridge



class ProjectsListViewController : GitHubListViewController<Repository> {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		cellIdentifier = "ProjectCell"
		
		let t = title
		title = nil; title = t
	}
	
	override func configureCell(_ cell: UITableViewCell, element: Repository) {
		cell.textLabel?.text = element.fullName
	}
	
	override func collectionLoaderHelper(for searchText: String?, context: NSManagedObjectContext) -> CoreDataSearchCLH<Repository, GitHubBMOBridge, GitHubPageInfoRetriever> {
		let fetchRequest: NSFetchRequest<Repository> = Repository.fetchRequest()
		
		let apiOrderProperty: NSAttributeDescription?
		let deletionDateProperty: NSAttributeDescription
		if let t = searchText?.trimmingCharacters(in: .whitespaces), !t.isEmpty {
			let fr: NSFetchRequest<Repository> = Repository.fetchRequest()
			fr.predicate = NSPredicate(format: "%K != NULL", #keyPath(Repository.zDeletionDateInRepositoriesListSearch))
			if let r = try? AppDelegate.shared.context.fetch(fr) {
				for u in r {u.zDeletionDateInRepositoriesListSearch = nil}
				try? AppDelegate.shared.context.save()
			}
			
			apiOrderProperty = Repository.entity().attributesByName[#keyPath(Repository.zPosInSearchResults)]!
			deletionDateProperty = Repository.entity().attributesByName[#keyPath(Repository.zDeletionDateInRepositoriesListSearch)]!
			fetchRequest.predicate = NSPredicate(format: "%K LIKE[cd] %@", #keyPath(Repository.fullName), "*" + t + "*")
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Repository.zPosInSearchResults), ascending: false)]
		} else {
			apiOrderProperty = nil
			deletionDateProperty = Repository.entity().attributesByName[#keyPath(Repository.zDeletionDateInRepositoriesList)]!
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Repository.remoteId), ascending: true)]
		}
		
		return CoreDataSearchCLH(fetchRequest: fetchRequest, additionalFetchInfo: nil, apiOrderProperty: apiOrderProperty, deletionDateProperty: deletionDateProperty, context: AppDelegate.shared.context, pageInfoRetriever: AppDelegate.shared.pageInfoRetriever, requestManager: AppDelegate.shared.requestManager)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "ShowProject" else {return}
		guard let selectedRow = (sender as? UITableViewCell).flatMap({ tableView.indexPath(for: $0) }) else {return}
		
		let destinationVC = segue.destination as! ProjectViewController
		destinationVC.repository = resultsController.object(at: selectedRow)
	}
	
}
