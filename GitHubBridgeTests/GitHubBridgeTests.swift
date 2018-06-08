/*
 * GitHubBridgeTests.swift
 * GitHubBridgeTests
 *
 * Created by François Lamboley on 07/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import XCTest
@testable import GitHubBridge



class GitHubBridgeTests: XCTestCase {
   
   func testTokenRetrieval() {
		/* Please create a "github_clients_token.txt" file on your desktop for the
		 * test to pass. For the test to pass on iOS device (non-simulator), you
		 * must create the "github_clients_token.txt" in the “Desktop” folder of
		 * sandbox of the app on the device. */
		let op = GitHubBMOOperation(request: URLRequest(url: URL(string: "https://www.apple.com/")!))
		XCTAssertNotNil(op.token)
   }
   
}
