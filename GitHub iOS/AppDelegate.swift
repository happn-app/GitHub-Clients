/*
 * AppDelegate.swift
 * GitHub iOS
 *
 * Created by François Lamboley on 08/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import os.log
import UIKit

import AsyncOperationResult
import BMO
import BMO_CoreData

import GitHubBridge



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	static private(set) var shared: AppDelegate!
	
	private(set) var context: NSManagedObjectContext!
	private(set) var requestManager: RequestManager!
	private(set) var pageInfoRetriever: GitHubPageInfoRetriever!
	
	private(set) var tabBarController: UITabBarController!
	
	var window: UIWindow?
	
	override init() {
		super.init()
		
		assert(AppDelegate.shared == nil)
		AppDelegate.shared = self
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		let container = NSPersistentContainer(name: "GitHub", managedObjectModel: NSManagedObjectModel(contentsOf: Bundle(for: GitHubBMOBridge.self).url(forResource: "GitHub", withExtension: "momd")!)!)
		container.loadPersistentStores(completionHandler: { _, _ in })
		context = container.viewContext
		
		requestManager = RequestManager(bridges: [GitHubBMOBridge(dbModel: container.managedObjectModel)], resultsImporterFactory: BMOBackResultsImporterForCoreDataWithFastImportRepresentationFactory())
		pageInfoRetriever = GitHubPageInfoRetriever()
		
		tabBarController = (window!.rootViewController! as! UITabBarController)
		
		/* Let's fetch the connected username (if any) and add the “you” tab if we
		 * get a result. */
		GitHubBMOOperation.retrieveUsernameFromToken{ username in
			guard let username = username else {return}
			DispatchQueue.main.async{
				var hasAddedController = false
				let addUserController = { (user: User?) -> Void in
					guard !hasAddedController, let user = user else {return}
					
					let youNavigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "YouNavigationViewController") as! UINavigationController
					let userViewController = youNavigationController.viewControllers.first! as! UserViewController
					userViewController.shouldRefreshUserOnLoad = false
					userViewController.title = "You"
					userViewController.user = user
					
					self.tabBarController.viewControllers?.append(youNavigationController)
					hasAddedController = true
				}
				let (u, _) = self.requestManager.unsafeFetchObject(withRemoteId: username, remoteIdAttributeName: "username", onContext: self.context, handler: { (u: User?, _: AsyncOperationResult<BridgeBackRequestResult<GitHubBMOBridge>>) in
					addUserController(u)
				})
				addUserController(u)
			}
		}
		
		return true
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
	}
	
	private struct BMOBackResultsImporterForCoreDataWithFastImportRepresentationFactory : AnyBackResultsImporterFactory {
		
		func createResultsImporter<BridgeType : Bridge>() -> AnyBackResultsImporter<BridgeType>? {
			assert(BridgeType.self == GitHubBMOBridge.self)
			return (AnyBackResultsImporter(importer: BackResultsImporterForCoreDataWithFastImportRepresentation<GitHubBMOBridge>(uniquingPropertyName: "bmoId")) as! AnyBackResultsImporter<BridgeType>)
		}
		
	}
	
}
