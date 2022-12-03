/*
Copyright 2018 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

import XCTest
@testable import GitHubBridge



class GitHubBridgeTests: XCTestCase {
	
	func testTokenRetrieval() {
		/* Please create a "github_clients_token.txt" file on your desktop for the test to pass.
		 * For the test to pass on iOS device (non-simulator), you must create the "github_clients_token.txt" in the “Desktop” folder of sandbox of the app on the device. */
		XCTAssertNotNil(GitHubBMOOperation.gitHubToken)
	}
	
}
