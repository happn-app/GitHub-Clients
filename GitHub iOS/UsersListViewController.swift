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

import CollectionLoader_RESTCoreData

import GitHubBridge



class UsersListViewController : GitHubListViewController<User> {
	
	enum UsersSource {
		
		case searchAll
		case stargazers(of: Repository)
		case watchers(of: Repository)
		
	}
	
	var usersSource = UsersSource.searchAll
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		cellIdentifier = "UserCell"
		
		let t = title
		title = nil; title = t
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "ShowUser"?:
			guard let selectedRow = (sender as? UITableViewCell).flatMap({ tableView.indexPath(for: $0) }) else {return}
			
			let userViewController = segue.destination as! UserViewController
			userViewController.user = resultsController.object(at: selectedRow)
			
		default: (/*nop*/)
		}
	}
	
	override func configureCell(_ cell: UITableViewCell, element: User) {
		cell.textLabel?.text = element.username
	}
	
	override func collectionLoaderHelper(for searchText: String?, context: NSManagedObjectContext) -> CoreDataSearchCLH<User, GitHubBMOBridge, GitHubPageInfoRetriever> {
		let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
		
		let userEntity = User.entity()
		let ephemeralDeletionDateProperty = userEntity.attributesByName[#keyPath(User.zEphemeralDeletionDate)]!
		
		let deletionDateProperty: NSAttributeDescription
		switch usersSource {
		case .searchAll:
			if let t = searchText?.trimmingCharacters(in: .whitespaces), !t.isEmpty {
				nullify(property: ephemeralDeletionDateProperty, inInstancesOf: userEntity, context: AppDelegate.shared.context)
				
				deletionDateProperty = ephemeralDeletionDateProperty
				fetchRequest.predicate = NSPredicate(format: "%K LIKE[cd] %@", #keyPath(User.username), t + "*")
				fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.username), ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
			} else {
				deletionDateProperty = userEntity.attributesByName[#keyPath(User.zDeletionDateInUsersList)]!
				fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.remoteId), ascending: true)]
			}
			
		case .stargazers(of: let repo):
			nullify(property: ephemeralDeletionDateProperty, inInstancesOf: userEntity, context: AppDelegate.shared.context)
			deletionDateProperty = ephemeralDeletionDateProperty
			
			fetchRequest.predicate = NSPredicate(format: "%K CONTAINS %@", #keyPath(User.starredRepositories), repo)
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.remoteId), ascending: true)]
			
		case .watchers(of: let repo):
			nullify(property: ephemeralDeletionDateProperty, inInstancesOf: userEntity, context: AppDelegate.shared.context)
			deletionDateProperty = ephemeralDeletionDateProperty
			
			fetchRequest.predicate = NSPredicate(format: "%K CONTAINS %@", #keyPath(User.watchedRepositories), repo)
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.remoteId), ascending: true)]
		}
		
		return CoreDataSearchCLH(fetchRequest: fetchRequest, additionalFetchInfo: nil, deletionDateProperty: deletionDateProperty, context: AppDelegate.shared.context, pageInfoRetriever: AppDelegate.shared.pageInfoRetriever, requestManager: AppDelegate.shared.requestManager)
	}
	
}
