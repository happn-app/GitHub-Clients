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

import BMO
import BMO_RESTCoreData
import GitHubBridge
import RESTUtils



class UsersListViewController : UITableViewController, UISearchControllerDelegate, UISearchResultsUpdating {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		title = "Users"
		
		/* ***** Configuring the Search Controller ***** */
		searchController = UISearchController(searchResultsController: nil)
		searchController.delegate = self
		searchController.searchResultsUpdater = self
		searchController.hidesNavigationBarDuringPresentation = true
		searchController.obscuresBackgroundDuringPresentation = false
		
		navigationItem.searchController = searchController
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
		return cell
	}
	
	/* *******************************
      MARK: - Search Results Updating
	   ******************************* */
	
	func updateSearchResults(for searchController: UISearchController) {
		print(searchController.searchBar.text!)
	}
	
	/* ***************
      MARK: - Private
	   *************** */
	
	private var searchController: UISearchController!
	
}
