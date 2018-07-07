/*
 * GitHubPageInfoRetriever.swift
 * GitHub Clients
 *
 * Created by François Lamboley on 07/07/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation

import BMO
import BMO_CoreData
import CollectionLoader_RESTCoreData
import RESTUtils



public class GitHubPageInfoRetriever : PageInfoRetriever {
	
	public typealias BridgeType = GitHubBMOBridge
	
	public let context: NSManagedObjectContext
	
	public init(context c: NSManagedObjectContext) {
		context = c
	}
	
	public func pageInfoFor(startOffset: Int, endOffset: Int) -> Any {
		return RESTMaxIdPaginatorInfo(maxReachedId: nil, count: endOffset-startOffset)
	}
	
	/* Note: Instead of fetching the latest object retrieved from the previous
	 *       load (which forces the page info retriever to have a reference to
	 *       the Core Data context and do a CD context switch), we could use the
	 *       Link header GitHub sends in its response. (Doc actually strongly
	 *       advise us to do so...) */
	public func nextPageInfo(for completionResults: BridgeBackRequestResult<GitHubBMOBridge>, from pageInfo: Any, nElementsPerPage: Int) -> Any?? {
		guard let objectID = completionResults.returnedObjectIDsAndRelationships.last?.objectID else {return .some(nil)}
		var ret: Any??
		context.performAndWait{
			ret = (try? self.context.existingObject(with: objectID) as? User)?.flatMap{ RESTMaxIdPaginatorInfo(maxReachedId: $0.bmoId, count: nElementsPerPage) }
		}
		return ret
	}
	
	public func previousPageInfo(for completionResults: BridgeBackRequestResult<GitHubBMOBridge>, from pageInfo: Any, nElementsPerPage: Int) -> Any? {
		return nil
	}
	
}
