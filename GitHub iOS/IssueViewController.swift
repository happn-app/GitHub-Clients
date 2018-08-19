/*
 * IssueViewController.swift
 * GitHub iOS
 *
 * Created by François Lamboley on 19/08/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation
import UIKit

import BMO
import BMO_RESTCoreData
import GitHubBridge



class IssueViewController : UIViewController, NSFetchedResultsControllerDelegate {
	
	var issue: Issue!
	
	@IBOutlet var labelIssueName: UILabel!
	@IBOutlet var labelIssueDescription: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let t = (issue.repository?.name.flatMap{ $0 + " — " } ?? "") + "#" + String(issue.issueNumber)
		title = nil; title = t
		
		let fetchRequest: NSFetchRequest<Issue> = Issue.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "SELF == %@", issue)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Issue.issueNumber), ascending: true)]
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: issue.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
		
		self.fetchedResultsController?.delegate = self
		try! self.fetchedResultsController?.performFetch()
		
		let _: BackRequestOperation<RESTCoreDataFetchRequest, GitHubBMOBridge> = AppDelegate.shared.requestManager.fetchObject(fromFetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>, additionalRequestInfo: nil, onContext: AppDelegate.shared.context)
		
		updateUI()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		let w = view.bounds.width - view.layoutMargins.left - view.layoutMargins.right
		
		labelIssueName.preferredMaxLayoutWidth = w
		labelIssueDescription.preferredMaxLayoutWidth = w
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		default: (/*nop*/)
		}
	}
	
	/* *******************************************
	   MARK: - Fetched Results Controller Delegate
	   ******************************************* */
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		updateUI()
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private var fetchedResultsController: NSFetchedResultsController<Issue>!
	
	private func updateUI() {
		guard let issue = fetchedResultsController?.fetchedObjects?.first else {
			labelIssueDescription.text = ""
			labelIssueName.text = "Error"
			return
		}
		
		labelIssueName.text = issue.title
		labelIssueDescription.text = issue.descr
	}
	
}
