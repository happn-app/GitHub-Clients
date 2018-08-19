/*
 * GistViewController.swift
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



class GistViewController : UITableViewController, NSFetchedResultsControllerDelegate {
	
	var gist: Gist!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let t = gist.firstFileName ?? "<unnamed>"
		title = nil; title = t
		
		let fetchRequest: NSFetchRequest<Gist> = Gist.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "SELF == %@", gist)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Gist.bmoId), ascending: true)]
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: gist.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
		
		self.fetchedResultsController?.delegate = self
		try! self.fetchedResultsController?.performFetch()
		
		let _: BackRequestOperation<RESTCoreDataFetchRequest, GitHubBMOBridge> = AppDelegate.shared.requestManager.fetchObject(fromFetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>, additionalRequestInfo: nil, onContext: AppDelegate.shared.context)
		
		tableView.reloadData()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		default: (/*nop*/)
		}
	}
	
	/* *****************************************
      MARK: - Table View Data Source & Delegate
	   ***************************************** */
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0: return 1
		case 1: return gist.files?.count ?? 0
		default: fatalError()
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case 0:
			let cell = tableView.dequeueReusableCell(withIdentifier: "DescriptionCell", for: indexPath)
			cell.textLabel?.text = (gist.descr?.isEmpty ?? true ? "<No description>" : gist.descr)
			return cell
			
		case 1:
			let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
			cell.textLabel?.text = (gist.files!.object(at: indexPath.row) as! File).filename
			return cell
			
		default:
			fatalError()
		}
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0: return "Description"
		case 1: return "Files"
		default: fatalError()
		}
	}
	
	/* *******************************************
	   MARK: - Fetched Results Controller Delegate
	   ******************************************* */
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.reloadData()
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private var fetchedResultsController: NSFetchedResultsController<Gist>!
	
}
