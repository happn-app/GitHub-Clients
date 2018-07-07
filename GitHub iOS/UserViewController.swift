/*
 * UserViewController.swift
 * GitHub iOS
 *
 * Created by François Lamboley on 10/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation
import UIKit

import AsyncOperationResult
import BMO
import BMO_RESTCoreData
import GitHubBridge
import RESTUtils



class UserViewController : UIViewController, NSFetchedResultsControllerDelegate {
	
	var user: User!
	
	@IBOutlet var labelUsername: UILabel!
	
	@IBOutlet var buttonPublicRepos: UIButton!
	@IBOutlet var buttonPublicGists: UIButton!
	@IBOutlet var buttonAssignedIssues: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let t = title
		title = nil; title = t
		
		let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "SELF == %@", user)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.username), ascending: true)]
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: user.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
		
		self.fetchedResultsController?.delegate = self
		try! self.fetchedResultsController?.performFetch()
		
		updateUI()
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
	
	private var fetchedResultsController: NSFetchedResultsController<User>!
	
	private func updateUI() {
		guard let user = fetchedResultsController?.fetchedObjects?.first else {
			labelUsername.text = "Error"
			return
		}
		
		labelUsername.text = user.username
		
		/* Both performWithoutAnimation and layoutIfNeeded are needed to avoid the
		 * animations on the buttons when changing the title... */
		UIView.performWithoutAnimation{
			buttonPublicRepos.setTitle("See Public Repositories (\(user.publicReposCount))", for: .normal)
			buttonPublicGists.setTitle("See Public Gists (\(user.publicGistsCount))", for: .normal)
			buttonPublicRepos.layoutIfNeeded()
			buttonPublicGists.layoutIfNeeded()
		}
	}
	
}
