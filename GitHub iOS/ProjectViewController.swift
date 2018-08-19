/*
 * ProjectViewController.swift
 * GitHub iOS
 *
 * Created by François Lamboley on 11/08/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation
import UIKit

import BMO
import BMO_RESTCoreData

import GitHubBridge



class ProjectViewController : UIViewController, NSFetchedResultsControllerDelegate {
	
	var repository: Repository!
	
	@IBOutlet var labelProjectName: UILabel!
	@IBOutlet var labelProjectDescription: UILabel!
	
	@IBOutlet var buttonSeeIssues: UIButton!
	@IBOutlet var buttonSeeStargazers: UIButton!
	@IBOutlet var buttonSeeWatchers: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let t = repository.name
		title = nil; title = t
		
		let fetchRequest: NSFetchRequest<Repository> = Repository.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "SELF == %@", repository)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Repository.name), ascending: true)]
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: repository.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
		
		self.fetchedResultsController?.delegate = self
		try! self.fetchedResultsController?.performFetch()
		
		let _: BackRequestOperation<RESTCoreDataFetchRequest, GitHubBMOBridge> = AppDelegate.shared.requestManager.fetchObject(fromFetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>, additionalRequestInfo: nil, onContext: AppDelegate.shared.context)
		
		updateUI()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "ShowStargazers"?:
			let usersListViewController = segue.destination as! UsersListViewController
			usersListViewController.usersSource = .stargazers(of: repository)
			
		case "ShowWatchers"?:
			let usersListViewController = segue.destination as! UsersListViewController
			usersListViewController.usersSource = .watchers(of: repository)
			
		case "ShowOpenIssues"?:
			()
			
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
	
	private var fetchedResultsController: NSFetchedResultsController<Repository>!
	
	private func updateUI() {
		guard let repository = fetchedResultsController?.fetchedObjects?.first else {
			labelProjectDescription.isHidden = true
			labelProjectName.text = "Error"
			return
		}
		
		labelProjectName.text = repository.fullName
		labelProjectDescription.isHidden = false
		labelProjectDescription.text = (repository.descr?.isEmpty ?? true ? "<No Description>" : repository.descr)
		
		/* Both performWithoutAnimation and layoutIfNeeded are needed to avoid the
		 * animations on the buttons when changing the title... */
		UIView.performWithoutAnimation{
			buttonSeeIssues.setTitle("See Open Issues (\(repository.openIssuesCount))", for: .normal)
			buttonSeeWatchers.setTitle("See Watchers (\(repository.watchersCount))", for: .normal)
			buttonSeeStargazers.setTitle("See Stargazers (\(repository.stargazersCount))", for: .normal)
			buttonSeeIssues.layoutIfNeeded()
			buttonSeeWatchers.layoutIfNeeded()
			buttonSeeStargazers.layoutIfNeeded()
		}
	}
	
}
