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



public class GitHubBMOOperation : RetryingOperation {
	
	public static var gitHubToken: String? {
		/* Let's read the token from a hard-coded file */
		let desktopPath = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first!
		let re = try! NSRegularExpression(pattern: "/Users/([^/]*)/.*", options: [])
		let username = re.stringByReplacingMatches(in: desktopPath, options: [], range: NSRange(location: 0, length: (desktopPath as NSString).length), withTemplate: "$1")
		return (
			(try? String(contentsOf: URL(fileURLWithPath: "github_clients_token.txt", relativeTo: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first!)))) ??
			(try? String(contentsOf: URL(fileURLWithPath: "/Users/\(username)/Desktop/github_clients_token.txt")))
		)
	}
	
	public static func retrieveUsernameFromToken(_ handler: @escaping (_ username: String?) -> Void) {
		guard gitHubToken != nil else {handler(nil); return}
		if let u = cachedUsernameFromToken {handler(u); return}
		
		let retrieveUsernameOperation = GitHubBMOOperation(request: URLRequest(url: URL(string: "user", relativeTo: di.apiRoot)!))
		retrieveUsernameOperation.completionBlock = {
			cachedUsernameFromToken = (retrieveUsernameOperation.results.successValue as? [String: Any?])?["login"] as? String
			handler(cachedUsernameFromToken)
		}
		retrieveUsernameOperation.start()
	}
	
	public enum Err : Error {
		case operationNotFinished
		case okIsNotOk
		case unknownError
	}
	
	let request: URLRequest
	var results: AsyncOperationResult<Any> = .error(Err.operationNotFinished)
	
	init(request r: URLRequest) {
		request = r
	}
	
	public override func startBaseOperation(isRetry: Bool) {
		print("Starting GitHub BMO Operation with URLRequest \(request)")
		
		var authenticatedRequest = request
		if let token = GitHubBMOOperation.gitHubToken {
			print("   -> Authenticating request with token found in Desktop file")
			authenticatedRequest.addValue("token \(token)", forHTTPHeaderField: "Authorization")
		}
		
		Alamofire.request(authenticatedRequest).validate().responseJSON{ response in
//			print(response.result.value)
			if let parsedJSON = response.result.value {
				self.results = .success(parsedJSON)
			} else {
				self.results = .error(response.error ?? Err.unknownError)
			}
			self.baseOperationEnded()
		}
	}
	
	public override var isAsynchronous: Bool {
		return true
	}
	
	private static var cachedUsernameFromToken: String?
	
}
