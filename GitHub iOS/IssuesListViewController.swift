/*
 * IssuesListViewController.swift
 * GitHub iOS
 *
 * Created by François Lamboley on 19/08/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation
import UIKit

import CollectionLoader_RESTCoreData
import GitHubBridge



class IssuesListViewController : GitHubListViewController<Issue> {
	
	enum IssuesSource {
		
		case from(project: Repository)
		
	}
	
	var issuesSource: IssuesSource!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		cellIdentifier = "IssueCell"
		
		let t = title
		title = nil; title = t
	}
	
	override var shouldShowSearchBar: Bool {
		return false
	}
	
	override var numberOfElementsPerPage: Int {
		return 75
	}
	
	override func configureCell(_ cell: UITableViewCell, element: Issue) {
		cell.textLabel?.text = element.title
	}
	
	override func collectionLoaderHelper(for searchText: String?, context: NSManagedObjectContext) -> CoreDataSearchCLH<Issue, GitHubBMOBridge, GitHubPageInfoRetriever> {
		assert(searchText == nil)
		let fetchRequest: NSFetchRequest<Issue> = Issue.fetchRequest()
		
		let issueEntity = Issue.entity()
		let ephemeralDeletionDateProperty = issueEntity.attributesByName[#keyPath(Gist.zEphemeralDeletionDate)]!
		
		let deletionDateProperty: NSAttributeDescription
		switch issuesSource! {
		case .from(project: let repository):
			nullify(property: ephemeralDeletionDateProperty, inInstancesOf: issueEntity, context: AppDelegate.shared.context)
			deletionDateProperty = ephemeralDeletionDateProperty
			fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Issue.repository), repository)
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Gist.creationDate), ascending: false)]
		}
		return CoreDataSearchCLH(fetchRequest: fetchRequest, additionalFetchInfo: nil, deletionDateProperty: deletionDateProperty, context: AppDelegate.shared.context, pageInfoRetriever: AppDelegate.shared.pageInfoRetriever, requestManager: AppDelegate.shared.requestManager)
	}
	
}
