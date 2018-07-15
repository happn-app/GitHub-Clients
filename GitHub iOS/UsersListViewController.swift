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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		cellIdentifier = "UserCell"
		
		let t = title
		title = nil; title = t
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		assert(segue.identifier == "ShowUser")
		let userViewController = segue.destination as! UserViewController
		userViewController.user = resultsController.object(at: tableView.indexPathForSelectedRow!)
	}
	
	override func configureCell(_ cell: UITableViewCell, element: User) {
		cell.textLabel?.text = element.username
	}
	
	override func collectionLoaderHelper(for searchText: String?, context: NSManagedObjectContext) -> CoreDataSearchCLH<User, GitHubBMOBridge, GitHubPageInfoRetriever> {
		let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
		
		let deletionDateProperty: NSAttributeDescription
		if let t = searchText?.trimmingCharacters(in: .whitespaces), !t.isEmpty {
			let fr: NSFetchRequest<User> = User.fetchRequest()
			fr.predicate = NSPredicate(format: "%K != NULL", #keyPath(User.zDeletionDateInUsersListSearch))
			if let r = try? AppDelegate.shared.context.fetch(fr) {
				for u in r {u.zDeletionDateInUsersListSearch = nil}
				try? AppDelegate.shared.context.save()
			}
			
			deletionDateProperty = User.entity().attributesByName[#keyPath(User.zDeletionDateInUsersListSearch)]!
			fetchRequest.predicate = NSPredicate(format: "%K LIKE[cd] %@", #keyPath(User.username), t + "*")
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.username), ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
		} else {
			deletionDateProperty = User.entity().attributesByName[#keyPath(User.zDeletionDateInUsersList)]!
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.remoteId), ascending: true)]
		}
		
		return CoreDataSearchCLH(fetchRequest: fetchRequest, additionalFetchInfo: nil, deletionDateProperty: deletionDateProperty, context: AppDelegate.shared.context, pageInfoRetriever: AppDelegate.shared.pageInfoRetriever, requestManager: AppDelegate.shared.requestManager)
	}
	
}
