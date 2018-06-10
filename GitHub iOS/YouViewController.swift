/*
 * YouViewController.swift
 * GitHub iOS
 *
 * Created by François Lamboley on 10/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation
import UIKit

import BMO
import BMO_RESTCoreData
import GitHubBridge
import RESTUtils



class YouViewController : UITableViewController {
	
	var myUsername: String?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		GitHubBMOOperation.retrieveUsernameFromToken{ username in
			self.myUsername = username
			guard let username = self.myUsername else {return}
			
			let (u, _): (User?, BackRequestOperation<RESTCoreDataFetchRequest, GitHubBMOBridge>) = AppDelegate.shared.requestManager.unsafeFetchObject(withRemoteId: username, remoteIdAttributeName: "username", onContext: AppDelegate.shared.context)
			print(u)
		}
	}
	
}
