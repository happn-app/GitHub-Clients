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



class UsersListViewController : UITableViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
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
	
}
