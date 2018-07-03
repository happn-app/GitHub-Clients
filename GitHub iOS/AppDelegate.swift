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

import BMO
import BMO_CoreData
import GitHubBridge



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	static private(set) var shared: AppDelegate!
	
	private(set) var context: NSManagedObjectContext!
	private(set) var requestManager: RequestManager!
	
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
		
		tabBarController = (window!.rootViewController! as! UITabBarController)
		
		/* Let's fetch the connected username (if any) and add the “you” tab if we
		 * get a result. */
		GitHubBMOOperation.retrieveUsernameFromToken{ username in
			DispatchQueue.main.async{
				let youNavigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "YouNavigationViewController")
				self.tabBarController.viewControllers?.append(youNavigationController)
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
