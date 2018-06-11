/*
 * YouViewController.swift
 * GitHub iOS
 *
 * Created by François Lamboley on 10/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation
import UIKit

import BMO
import BMO_RESTCoreData
import GitHubBridge
import RESTUtils



class YouViewController : UIViewController, NSFetchedResultsControllerDelegate {
	
	@IBOutlet var labelUsername: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		title = "You"
		
		GitHubBMOOperation.retrieveUsernameFromToken{ username in
			self.myUsername = username
			guard let username = self.myUsername else {
				self.updateUI()
				return
			}
			
			let context = AppDelegate.shared.context!
			let requestManager = AppDelegate.shared.requestManager!
			let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
			fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(User.username), username)
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.username), ascending: true)]
			self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
			
			self.fetchedResultsController?.delegate = self
			try! self.fetchedResultsController?.performFetch()
			self.updateUI()
			
			let _: BackRequestOperation<RESTCoreDataFetchRequest, GitHubBMOBridge> = requestManager.fetchObject(
				fromFetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>, additionalRequestInfo: nil,
				fetchType: .onlyIfNoLocalResults, onContext: context
			)
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
	
	private var myUsername: String?
	
	private var fetchedResultsController: NSFetchedResultsController<User>?
	
	private func updateUI() {
		guard let user = fetchedResultsController?.fetchedObjects?.first else {
			self.labelUsername.text = "Error"
			return
		}
		
		title = user.username
		labelUsername.text = user.username
	}
	
}
