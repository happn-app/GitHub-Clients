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
		
		let repositoryEntity = Repository.entity()
		let ephemeralDeletionDateProperty = repositoryEntity.attributesByName[#keyPath(Repository.zEphemeralDeletionDate)]!
		
		let apiOrderProperty: NSAttributeDescription?
		let deletionDateProperty: NSAttributeDescription
		if let t = searchText?.trimmingCharacters(in: .whitespaces), !t.isEmpty {
			nullify(property: ephemeralDeletionDateProperty, inInstancesOf: repositoryEntity, context: AppDelegate.shared.context)
			
			deletionDateProperty = ephemeralDeletionDateProperty
			apiOrderProperty = repositoryEntity.attributesByName[#keyPath(Repository.zPosInSearchResults)]!
			fetchRequest.predicate = NSPredicate(format: "%K LIKE[cd] %@", #keyPath(Repository.fullName), "*" + t + "*")
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Repository.zPosInSearchResults), ascending: false)]
		} else {
			apiOrderProperty = nil
			deletionDateProperty = repositoryEntity.attributesByName[#keyPath(Repository.zDeletionDateInRepositoriesList)]!
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
