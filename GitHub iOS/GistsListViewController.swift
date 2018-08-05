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

import GitHubBridge
import CollectionLoader_RESTCoreData



class GistsListViewController: GitHubListViewController<Gist> {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		cellIdentifier = "GistCell"
		
		let t = title
		title = nil; title = t
	}
	
	override var numberOfElementsPerPage: Int {
		return 75
	}
	
	override func configureCell(_ cell: UITableViewCell, element: Gist) {
		cell.textLabel?.text = element.firstFileName
	}
	
	override func collectionLoaderHelper(for searchText: String?, context: NSManagedObjectContext) -> CoreDataSearchCLH<Gist, GitHubBMOBridge, GitHubPageInfoRetriever> {
		let fetchRequest: NSFetchRequest<Gist> = Gist.fetchRequest()
		
		let deletionDateProperty: NSAttributeDescription
		if let t = searchText?.trimmingCharacters(in: .whitespaces), !t.isEmpty {
			let fr: NSFetchRequest<Gist> = Gist.fetchRequest()
			fr.predicate = NSPredicate(format: "%K != NULL", #keyPath(Gist.zDeletionDateInGistListSearch))
			if let r = try? AppDelegate.shared.context.fetch(fr) {
				for u in r {u.zDeletionDateInGistListSearch = nil}
				try? AppDelegate.shared.context.save()
			}
			
			deletionDateProperty = Gist.entity().attributesByName[#keyPath(Gist.zDeletionDateInGistListSearch)]!
			fetchRequest.predicate = NSPredicate(format: "%K LIKE[cd] %@", #keyPath(Gist.firstFileName), t + "*")
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Gist.firstFileName), ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
		} else {
			deletionDateProperty = Gist.entity().attributesByName[#keyPath(Gist.zDeletionDateInGistList)]!
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Gist.creationDate), ascending: false)]
		}
		
		return CoreDataSearchCLH(fetchRequest: fetchRequest, additionalFetchInfo: nil, deletionDateProperty: deletionDateProperty, context: AppDelegate.shared.context, pageInfoRetriever: AppDelegate.shared.pageInfoRetriever, requestManager: AppDelegate.shared.requestManager)
	}
	
}
