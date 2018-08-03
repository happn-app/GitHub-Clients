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
	
	public init() {
	}
	
	public func pageInfoFor(startOffset: Int, endOffset: Int) -> Any {
		return RESTURLAndCountPaginatorInfo(url: nil, count: endOffset-startOffset)
	}
	
	/* Note: Instead of fetching the latest object retrieved from the previous
	 *       load (which forces the page info retriever to have a reference to
	 *       the Core Data context and do a CD context switch), we could use the
	 *       Link header GitHub sends in its response. (Doc actually strongly
	 *       advise us to do so...) */
	public func nextPageInfo(for completionResults: BridgeBackRequestResult<GitHubBMOBridge>, from pageInfo: Any, nElementsPerPage: Int) -> Any?? {
		guard let linkHeader = completionResults.metadata?.responseHeaders?["Link"] as? String else {return nil}
		guard let linkValues = LinkHeaderParser.parseLinkHeader(linkHeader, defaultContext: nil, contentLanguageHeader: nil) else {return nil}
		guard let linkNext = linkValues.first(where: { $0.rel.contains("next") })?.link else {return nil}
		return RESTURLAndCountPaginatorInfo(url: linkNext, count: nElementsPerPage)
		
		/* Note: Using a RESTMaxIdPaginator we can also get the latest retrieved
		 * id of the elements we retrieved and return a RESTMaxIdPaginatorInfo in
		 * this function. GitHub strongly recommends against manually dealing with
		 * pagination and instead use the Link header, so this is what we do.
		 * Below is an implementation of the alternative for reference. It does
		 * require the page info retriever to be allocated with a reference to the
		 * CoreData context. */
//		guard let objectID = completionResults.returnedObjectIDsAndRelationships.last?.objectID else {return .some(nil)}
//		var ret: Any??
//		context.performAndWait{
//			ret = (try? self.context.existingObject(with: objectID) as? User)?.flatMap{ RESTMaxIdPaginatorInfo(maxReachedId: $0.bmoId, count: nElementsPerPage) }
//		}
//		return ret
	}
	
	public func previousPageInfo(for completionResults: BridgeBackRequestResult<GitHubBMOBridge>, from pageInfo: Any, nElementsPerPage: Int) -> Any? {
		guard let linkHeader = completionResults.metadata?.responseHeaders?["Link"] as? String else {return nil}
		guard let linkValues = LinkHeaderParser.parseLinkHeader(linkHeader, defaultContext: nil, contentLanguageHeader: nil) else {return nil}
		guard let linkPrev = linkValues.first(where: { $0.rel.contains("prev") })?.link else {return nil}
		return RESTURLAndCountPaginatorInfo(url: linkPrev, count: nElementsPerPage)
	}
	
}
