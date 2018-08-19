/*
 * GistFileViewController.swift
 * GitHub iOS
 *
 * Created by François Lamboley on 19/08/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation
import UIKit

import Alamofire
import GitHubBridge



class GistFileViewController : UIViewController {
	
	var file: File!
	
	@IBOutlet var textView: UITextView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let t = file.filename ?? "<unnamed>"
		title = nil; title = t
		
		guard let url = file.rawURL else {
			textView.text = "Loading Error…"
			return
		}
		
		Alamofire.request(url).responseString{ response in
			self.textView.text = response.result.value ?? "Loading Error…"
		}
	}
	
}
