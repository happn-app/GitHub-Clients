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

import AsyncOperationResult
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
			DispatchQueue.main.async{
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
				
				self.loadingMe = true
				requestManager.fetchObject(
					fromFetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>, additionalRequestInfo: nil,
					fetchType: .onlyIfNoLocalResults, onContext: context, handler: { (_: User?, _: AsyncOperationResult<BridgeBackRequestResult<GitHubBMOBridge>>) in
						self.loadingMe = false
						/* We do monitor the fetched user, but not loadingMe… so we
						 * need to manually update the UI.
						 * Also, if there‘s a error fetching the user, it will not
						 * exist when the operation is done, so the fetched results
						 * controller will not have a notification that something has
						 * changed, and the update UI will never be called. */
						self.updateUI()
					}
				)
				
				self.updateUI()
			}
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
	
	private var loadingMe = false
	private var fetchedResultsController: NSFetchedResultsController<User>?
	
	private func updateUI() {
		guard let user = fetchedResultsController?.fetchedObjects?.first else {
			labelUsername.text = loadingMe ? "Loading…" : "Error"
			return
		}
		
		title = user.username
		labelUsername.text = user.username
	}
	
}
