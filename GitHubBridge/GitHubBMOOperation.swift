/*
 * GitHubBMOOperation.swift
 * GitHub Clients
 *
 * Created by François Lamboley on 07/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation

import Alamofire
import AsyncOperationResult
import RetryingOperation



class GitHubBMOOperation : RetryingOperation {
	
	enum Err : Error {
		case operationNotFinished
		case okIsNotOk
		case unknownError
	}
	
	let token: String?
	
	let request: URLRequest
	var results: AsyncOperationResult<[String: Any?]> = .error(Err.operationNotFinished)
	
	init(request r: URLRequest) {
		request = r
		
		/* Let's read the token from a hard-coded file */
		let desktopPath = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first!
		let re = try! NSRegularExpression(pattern: "/Users/([^/]*)/.*", options: [])
		let username = re.stringByReplacingMatches(in: desktopPath, options: [], range: NSRange(location: 0, length: (desktopPath as NSString).length), withTemplate: "$1")
		token = (
			(try? String(contentsOf: URL(fileURLWithPath: "github_clients_token.txt", relativeTo: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first!)))) ??
			(try? String(contentsOf: URL(fileURLWithPath: "/Users/\(username)/Desktop/github_clients_token.txt")))
		)
	}
	
	override func startBaseOperation(isRetry: Bool) {
		print("Starting GitHub BMO Operation with URLRequest \(request)")
		
		var authenticatedRequest = request
		if let token = token {
			print("   -> Authenticating request with token found in Desktop file")
			authenticatedRequest.addValue("token \(token)", forHTTPHeaderField: "Authorization")
		}
		
		Alamofire.request(authenticatedRequest).validate().responseJSON{ response in
			if let json = response.result.value as? [String: Any?] {
				self.results = .success(json)
			} else {
				self.results = .error(response.error ?? Err.unknownError)
			}
			self.baseOperationEnded()
		}
	}
	
	override var isAsynchronous: Bool {
		return true
	}
	
}
