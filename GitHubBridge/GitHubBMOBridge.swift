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

import CoreData
import Foundation

import BMO
import BMO_CoreData
import BMO_RESTCoreData
import RESTUtils



public struct GitHubBMOBridgeUserInfo {
	
	public var addedToMixedRepresentations: [String: Any]?
	
	init() {
		addedToMixedRepresentations = nil
	}
	
}

public struct GitHubBMOBridgeMetadata {
	
	public var responseHeaders: [AnyHashable: Any]?
	
}



public class GitHubBMOBridge : Bridge {
	
	public typealias DbType = NSManagedObjectContext
	public typealias AdditionalRequestInfoType = AdditionalRESTRequestInfo<NSPropertyDescription>
	
	public typealias UserInfoType = GitHubBMOBridgeUserInfo
	public typealias MetadataType = GitHubBMOBridgeMetadata
	
	public typealias RemoteObjectRepresentationType = [String: Any?]
	public typealias RemoteRelationshipAndMetadataRepresentationType = [[String: Any?]]
	
	public typealias BackOperationType = GitHubBMOOperation
	
	enum Err : Error {
		case cannotGetRESTPathForRequest
		case operationError(Error)
		case invalidAPIResponse
	}
	
	public init(dbModel m: NSManagedObjectModel) {
		dbModel = m
	}
	
	public func createUserInfoObject() -> UserInfoType {
		return GitHubBMOBridgeUserInfo()
	}
	
	public func backOperation(forFetchRequest fetchRequest: DbType.FetchRequestType, additionalInfo: AdditionalRequestInfoType?, userInfo: inout UserInfoType) throws -> BackOperationType? {
		let normalRESTPath: RESTPath?
		var restPathResolvingInfo: [String: Any] = [:]
		var additionalRESTPathResolvingInfo: [Any] = []
		var additionalInfo = additionalInfo ?? AdditionalRequestInfoType()
		
		do {
			let entity = fetchRequest.entity!
			switch entity.name! {
			case Gist.entity().name!:
				/* /gists                 <-- Lists gists of the connected user, or all public gists if nobody is connected */
				/* /gists/:gist_id        <-- Get one gist */
				/* /users/:username/gists <-- Lists gists of the specified user */
				/* /gists/public          <-- Lists all public gists */
				/* /gists/starred         <-- Lists authenticated user’s starred gists */
//				.restPath("(/users/|owner.username|)/gists(/|remoteId|)"),
				if (fetchRequest.predicate?.firstLevelConstants(forKeyPath: "owner") ?? []).count == 0 {
					/* We do not specify an owner for the searched gists, we assume all gists are searched */
					normalRESTPath = RESTPath("/gists/public")
				} else {
					/* Un-specific predicate, we use the generic REST path */
					normalRESTPath = restMapper.restPath(forEntity: entity, additionalRESTInfo: additionalInfo)
				}
				
			case Issue.entity().name!:
				/* /issues                            <-- Lists all issues assigned to authenticated user */
				/* /repos/:owner/:repo/issues         <-- Lists issues in a given repository */
				/* /repos/:owner/:repo/issues/:number <-- Get one issue */
				/* /user/issues                       <-- Lists issues assigned to authenticated user in owned and member repositories */
				/* /orgs/:org/issues                  <-- Lists issues assigned to authenticated user in the given org repositories */
//				.restPath("(/repos/|repository.owner.username|/|repository.name|)/issues(/|issueNumber|)"),
				let selfIssue = (fetchRequest.predicate?.firstLevelComparisonSubpredicates
					.filter{ $0.leftExpression.expressionType == .evaluatedObject || $0.rightExpression.expressionType == .evaluatedObject }
					.compactMap{ ($0.constantValueExpression?.constantValue as? Issue) })
					.flatMap{ $0.count == 1 ? $0.first : nil }
				
				normalRESTPath = restMapper.restPath(forEntity: entity, additionalRESTInfo: additionalInfo)
				
				if let selfIssue = selfIssue {
					additionalRESTPathResolvingInfo.append(selfIssue)
				}
				if let repositories = fetchRequest.predicate?.firstLevelConstants(forKeyPath: "repository", withOrCompound: true, withAndCompound: true) as? [Repository],
					let repository = repositories.first, repositories.count == 1
				{
					userInfo.addedToMixedRepresentations = userInfo.addedToMixedRepresentations ?? [:]
					userInfo.addedToMixedRepresentations!["repository"] = ["id": repository.remoteId]
				}
				
			case Label.entity().name!:
				/* /repos/:owner/:repo/labels                <-- Lists all labels in given repository */
				/* /repos/:owner/:repo/labels/:name          <-- Get one label */
				/* /repos/:owner/:repo/issues/:number/labels <-- Lists labels of a given issue */
//				.restPath("/repos/|repository.owner.username|/|repository.name|(/issues/|issue.issueNumber|)/labels(/|name|)"),
				normalRESTPath = restMapper.restPath(forEntity: entity, additionalRESTInfo: additionalInfo)
				
			case Repository.entity().name!:
				/* /repos/:owner/:repo    <-- Get one repository */
				/* /user/repos            <-- Lists all repositories on which the authenticated user has explicit permission to access */
				/* /users/:username/repos <-- Lists public repositories for the specified user */
				/* /orgs/:org/repos       <-- Lists repositories for the specified org */
				/* /repositories          <-- Lists all public repositories */
//				.restPath("/repos/|owner.username|/|name|"),
				let selfRepository = (fetchRequest.predicate?.firstLevelComparisonSubpredicates
					.filter{ $0.leftExpression.expressionType == .evaluatedObject || $0.rightExpression.expressionType == .evaluatedObject }
					.compactMap{ ($0.constantValueExpression?.constantValue as? Repository) })
					.flatMap{ $0.count == 1 ? $0.first : nil }
				let owners = fetchRequest.predicate?.firstLevelConstants(forKeyPath: "owner", withOrCompound: true, withAndCompound: true)
				if owners?.isEmpty ?? true && selfRepository == nil {
					/* We do not specify an owner for the searched repositories, we
					 * assume all repositories are searched or we're fetching a
					 * specific repository. */
					if let namePredicates = fetchRequest.predicate?.firstLevelComparisonSubpredicates
							.filter({ $0.keyPathExpression?.keyPath == "fullName" && $0.predicateOperatorType == .like && $0.comparisonPredicateModifier == .direct }),
						let namePredicate = namePredicates.first, namePredicates.count == 1,
						let searchedNameWithStars = namePredicate.constantValueExpression?.constantValue as? String,
						searchedNameWithStars.hasPrefix("*"), searchedNameWithStars.hasSuffix("*"), searchedNameWithStars != "**"
					{
						/* Search for repositories */
						let searchedName = searchedNameWithStars.dropFirst().dropLast()
						normalRESTPath = RESTPath("/search/repositories")
						additionalInfo.additionalRequestParameters["q"] = searchedName + " in:name"
//						additionalInfo.additionalRequestParameters["sort"] = "stars"
//						additionalInfo.additionalRequestParameters["order"] = "desc"
					} else {
						normalRESTPath = RESTPath("/repositories")
					}
				} else if let owners = owners as? [User], owners.count == 1 {
					normalRESTPath = RESTPath("/users/|owner.username|/repos")
					additionalInfo.additionalRequestParameters["sort"] = "updated"
					additionalInfo.additionalRequestParameters["direction"] = "desc"
				} else {
					/* Un-specific predicate, we use the generic REST path */
					normalRESTPath = restMapper.restPath(forEntity: entity, additionalRESTInfo: additionalInfo)
					if let selfRepository = selfRepository {
						additionalRESTPathResolvingInfo.append(selfRepository)
					}
				}
				
			case User.entity().name!:
				/* /users/:username <-- Get one user */
				/* /users           <-- Lists all the users */
				/* /user            <-- Get the authenticated user */
//				.restPath("/users(/|username|)"),
				if let usernamePredicates = fetchRequest.predicate?.firstLevelComparisonSubpredicates
						.filter({ $0.keyPathExpression?.keyPath == "username" && $0.predicateOperatorType == .like && $0.comparisonPredicateModifier == .direct }),
					let usernamePredicate = usernamePredicates.first, usernamePredicates.count == 1,
					let searchedUsernameWithStar = usernamePredicate.constantValueExpression?.constantValue as? String,
					searchedUsernameWithStar.hasSuffix("*"), searchedUsernameWithStar != "*"
				{
					/* Search for users */
					let searchedUsername = searchedUsernameWithStar.dropLast()
					normalRESTPath = RESTPath("/search/users")
					additionalInfo.additionalRequestParameters["q"] = searchedUsername + " in:login"
				} else if let starredRepositoriesPredicates = fetchRequest.predicate?.firstLevelComparisonSubpredicates
						.filter({ $0.keyPathExpression?.keyPath == "starredRepositories" && $0.predicateOperatorType == .contains }),
					let starredRepositoriesPredicate = starredRepositoriesPredicates.first, starredRepositoriesPredicates.count == 1,
					let starredRepository = starredRepositoriesPredicate.constantValueExpression?.constantValue as? Repository
				{
					normalRESTPath = RESTPath("/repos/|repo.owner.username|/|repo.name|/stargazers")
					restPathResolvingInfo["repo"] = starredRepository
					userInfo.addedToMixedRepresentations = userInfo.addedToMixedRepresentations ?? [:]
					userInfo.addedToMixedRepresentations!["starredRepositories"] = ["id": starredRepository.remoteId]
				} else if let watchedRepositoriesPredicates = fetchRequest.predicate?.firstLevelComparisonSubpredicates
						.filter({ $0.keyPathExpression?.keyPath == "watchedRepositories" && $0.predicateOperatorType == .contains }),
					let watchedRepositoriesPredicate = watchedRepositoriesPredicates.first, watchedRepositoriesPredicates.count == 1,
					let watchedRepository = watchedRepositoriesPredicate.constantValueExpression?.constantValue as? Repository
				{
					normalRESTPath = RESTPath("/repos/|repo.owner.username|/|repo.name|/subscribers")
					restPathResolvingInfo["repo"] = watchedRepository
					userInfo.addedToMixedRepresentations = userInfo.addedToMixedRepresentations ?? [:]
					userInfo.addedToMixedRepresentations!["watchedRepositories"] = ["id": watchedRepository.remoteId]
				} else {
					/* Un-specific predicate, we use the generic REST path */
					normalRESTPath = restMapper.restPath(forEntity: entity, additionalRESTInfo: additionalInfo)
					if let selfUsernames = fetchRequest.predicate?.firstLevelComparisonSubpredicates
							.filter({ $0.leftExpression.expressionType == .evaluatedObject || $0.rightExpression.expressionType == .evaluatedObject })
							.compactMap({ ($0.constantValueExpression?.constantValue as? User)?.username }),
						let selfUsername = selfUsernames.first, selfUsernames.count == 1
					{
						/* But we have a “SELF == user” predicate, so we set that in the REST path resolving info (not supported by the REST mapper)  */
						restPathResolvingInfo["username"] = selfUsername
					}
				}
				
			default:
				normalRESTPath = restMapper.restPath(forEntity: entity, additionalRESTInfo: additionalInfo)
			}
		}
		
		let paginatorRESTPath = additionalInfo.paginatorInfo.flatMap{ paginator.forcedRESTPath(withPaginatorInfo: $0) }
		let restPath = additionalInfo.forcedRESTPath ?? paginatorRESTPath ?? normalRESTPath
		
		/* Computing REST path values from request's predicate: We're enumerating
		 * all key/val pairs from comparison predicates in request predicate. Only
		 * one value per key is allowed for the key to stay in the final
		 * restPathValues dictionary. */
		var blacklistedKeys = Set<String>()
		fetchRequest.predicate?.enumerateFirstLevelConstants(forKeyPath: nil, withOrCompound: true, withAndCompound: true){ (keyPath, constant) in
			if restPathResolvingInfo[keyPath] == nil {restPathResolvingInfo[keyPath] = constant}
			else                                     {blacklistedKeys.insert(keyPath)}
		}
		for p in blacklistedKeys {restPathResolvingInfo.removeValue(forKey: p)}
		
		guard let path = restPath?.resolvedPath(sources: [restPathResolvingInfo] + additionalRESTPathResolvingInfo) else {
			throw Err.cannotGetRESTPathForRequest
		}
		
		var baseURLComponents = URLComponents(url: URL(string: path, relativeTo: di.apiRoot)!, resolvingAgainstBaseURL: true)!
		baseURLComponents.queryItems = (baseURLComponents.queryItems ?? []) + restMapper.parameters(fromAdditionalRESTInfo: additionalInfo, forEntity: fetchRequest.entity!).map{
			URLQueryItem(name: $0.key, value: String(describing: $0.value))
		}
		if baseURLComponents.queryItems?.isEmpty ?? false {baseURLComponents.queryItems = nil}
		
		var request = URLRequest(url: baseURLComponents.url!)
		request.cachePolicy = .reloadIgnoringLocalCacheData
		return GitHubBMOOperation(request: request)
	}
	
	public func backOperation(forInsertedObject insertedObject: DbType.ObjectType, additionalInfo: AdditionalRequestInfoType?, userInfo: inout UserInfoType) throws -> BackOperationType? {
		return nil
	}
	
	public func backOperation(forUpdatedObject updatedObject: DbType.ObjectType, additionalInfo: AdditionalRequestInfoType?, userInfo: inout UserInfoType) throws -> BackOperationType? {
		return nil
	}
	
	public func backOperation(forDeletedObject deletedObject: DbType.ObjectType, additionalInfo: AdditionalRequestInfoType?, userInfo: inout UserInfoType) throws -> BackOperationType? {
		return nil
	}
	
	public func error(fromFinishedOperation operation: BackOperationType) -> Error? {
		return operation.results.error
	}
	
	public func userInfo(fromFinishedOperation operation: BackOperationType, currentUserInfo: UserInfoType) -> UserInfoType {
		return currentUserInfo
	}
	
	public func bridgeMetadata(fromFinishedOperation operation: BackOperationType, userInfo: UserInfoType) -> MetadataType? {
		return GitHubBMOBridgeMetadata(responseHeaders: operation.responseHeaders)
	}
	
	public func remoteObjectRepresentations(fromFinishedOperation operation: BackOperationType, userInfo: UserInfoType) throws -> [RemoteObjectRepresentationType]? {
		switch operation.results {
		case .success(let success as [[String: Any?]]): return success
		case .success(let success as  [String: Any?]):  return success["items"] as? [[String: Any?]] ?? [success]
		case .error(let e): throw Err.operationError(e)
		default:            throw Err.invalidAPIResponse
		}
	}
	
	public func mixedRepresentation(fromRemoteObjectRepresentation remoteRepresentation: RemoteObjectRepresentationType, expectedEntity: DbType.EntityDescriptionType, userInfo: UserInfoType) -> MixedRepresentation<DbType.EntityDescriptionType, RemoteRelationshipAndMetadataRepresentationType, UserInfoType>? {
		guard let entity = restMapper.actualLocalEntity(forRESTRepresentation: remoteRepresentation, expectedEntity: expectedEntity) else {return nil}
		let mixedRepresentationDictionary = restMapper.mixedRepresentation(ofEntity: entity, fromRESTRepresentation: remoteRepresentation, userInfo: userInfo)
			.merging(userInfo.addedToMixedRepresentations ?? [:], uniquingKeysWith: { current, _ in current })
		let uniquingId = restMapper.uniquingId(forLocalRepresentation: mixedRepresentationDictionary, ofEntity: entity)
		return MixedRepresentation(entity: entity, uniquingId: uniquingId, mixedRepresentationDictionary: mixedRepresentationDictionary, userInfo: userInfo)
	}
	
	public func subUserInfo(forRelationshipNamed relationshipName: String, inEntity entity: DbType.EntityDescriptionType, currentMixedRepresentation: MixedRepresentation<DbType.EntityDescriptionType, RemoteRelationshipAndMetadataRepresentationType, UserInfoType>) -> UserInfoType {
		return GitHubBMOBridgeUserInfo()
	}
	
	public func metadata(fromRemoteRelationshipAndMetadataRepresentation remoteRelationshipAndMetadataRepresentation: RemoteRelationshipAndMetadataRepresentationType, userInfo: UserInfoType) -> MetadataType? {
		return nil
	}
	
	public func remoteObjectRepresentations(fromRemoteRelationshipAndMetadataRepresentation remoteRelationshipAndMetadataRepresentation: RemoteRelationshipAndMetadataRepresentationType, userInfo: UserInfoType) -> [RemoteObjectRepresentationType]? {
		return remoteRelationshipAndMetadataRepresentation
	}
	
	public func relationshipMergeType(forRelationshipNamed relationshipName: String, inEntity entity: DbType.EntityDescriptionType, currentMixedRepresentation: MixedRepresentation<DbType.EntityDescriptionType, RemoteRelationshipAndMetadataRepresentationType, UserInfoType>) -> DbRepresentationRelationshipMergeType<DbType.EntityDescriptionType, DbType.ObjectType> {
		guard relationshipName != "starredRepositories" && relationshipName != "watchedRepositories" else {return .append}
		return .replace
	}
	
	let dbModel: NSManagedObjectModel
	
	private var paginator = RESTURLAndCountPaginator(countKey: "per_page")
	
	private lazy var restMapper: RESTMapper<NSEntityDescription, NSPropertyDescription> = {
		let urlTransformer = RESTURLTransformer()
		let boolTransformer = RESTBoolTransformer()
		let colorTransformer = RESTColorTransformer()
		let dateTransformer = RESTDateAndTimeTransformer()
		let intTransformer = RESTNumericTransformer(numericFormat: .int)

		let intToStrTransformer = IntToStringTransformer()
		
		let FileMapping: [_RESTConvenienceMappingForEntity] = [
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				#keyPath(File.bmoId):       [.restName("id")],
				#keyPath(File.filename):    [.restName("filename")],
				#keyPath(File.isTruncated): [.restName("truncated"), .restToLocalTransformer(boolTransformer)],
				#keyPath(File.language):    [.restName("language")],
				#keyPath(File.mimeType):    [.restName("type")],
				#keyPath(File.rawURL):      [.restName("raw_url"),   .restToLocalTransformer(urlTransformer)],
				#keyPath(File.size):        [.restName("size"),      .restToLocalTransformer(intTransformer)]
			])
		]
		
		let FileLanguageMapping: [_RESTConvenienceMappingForEntity] = [
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				#keyPath(FileLanguage.bmoId): [.restName("name")],
				#keyPath(FileLanguage.name):  [.restName("name")]
			])
		]
		
		let GistMapping: [_RESTConvenienceMappingForEntity] = [
			/* /gists                 <-- Lists gists of the connected user, or all public gists if nobody is connected */
			/* /gists/:gist_id        <-- Get one gist */
			/* /users/:username/gists <-- Lists gists of the specified user */
			/* /gists/public          <-- Lists all public gists */
			/* /gists/starred         <-- Lists authenticated user’s starred gists */
			.restPath("(/users/|owner.username|)/gists(/|remoteId|)"),
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				#keyPath(Gist.bmoId):        [.restName("id")],
				#keyPath(Gist.creationDate): [.restName("created_at"),   .restToLocalTransformer(dateTransformer)],
				#keyPath(Gist.descr):        [.restName("description")],
				#keyPath(Gist.files):        [                           .restToLocalTransformer(FilesTransformer())],
				#keyPath(Gist.gitPullURL):   [.restName("git_pull_url"), .restToLocalTransformer(urlTransformer)],
				#keyPath(Gist.gitPushURL):   [.restName("git_push_url"), .restToLocalTransformer(urlTransformer)],
				#keyPath(Gist.isPublic):     [.restName("public"),       .restToLocalTransformer(boolTransformer)],
				#keyPath(Gist.isTruncated):  [.restName("truncated"),    .restToLocalTransformer(boolTransformer)],
				#keyPath(Gist.nodeId):       [.restName("nodeId")],
				#keyPath(Gist.owner):        [.restName("owner")],
				#keyPath(Gist.remoteId):     [.restName("id")],
				#keyPath(Gist.updateDate):   [.restName("updated_at"),   .restToLocalTransformer(dateTransformer)],
				#keyPath(Gist.zDeletionDateInGistList): [.localConstant(nil)],
				#keyPath(Gist.zEphemeralDeletionDate):  [.localConstant(nil)]
			])
		]
		
		let IssueMapping: [_RESTConvenienceMappingForEntity] = [
			/* /issues                            <-- Lists all issues assigned to authenticated user */
			/* /repos/:owner/:repo/issues         <-- Lists issues in a given repository */
			/* /repos/:owner/:repo/issues/:number <-- Get one issue */
			/* /user/issues                       <-- Lists issues assigned to authenticated user in owned and member repositories */
			/* /orgs/:org/issues                  <-- Lists issues assigned to authenticated user in the given org repositories */
			.restPath("(/repos/|repository.owner.username|/|repository.name|)/issues(/|issueNumber|)"),
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				#keyPath(Issue.activeLockReason): [.restName("active_lock_reason")],
				#keyPath(Issue.assignees):        [.restName("assignees")],
				#keyPath(Issue.bmoId):            [.restName("id"),                 .restToLocalTransformer(intToStrTransformer)],
				#keyPath(Issue.closeDate):        [.restName("closed_at"),          .restToLocalTransformer(dateTransformer)],
				#keyPath(Issue.commentsCount):    [.restName("comments"),           .restToLocalTransformer(intTransformer)],
				#keyPath(Issue.creationDate):     [.restName("created_at"),         .restToLocalTransformer(dateTransformer)],
				#keyPath(Issue.descr):            [.restName("body")],
				#keyPath(Issue.isLocked):         [.restName("locked"),             .restToLocalTransformer(boolTransformer)],
				#keyPath(Issue.labels):           [.restName("labels")],
				#keyPath(Issue.nodeId):           [.restName("node_id")],
				#keyPath(Issue.issueNumber):      [.restName("number"),             .restToLocalTransformer(intTransformer)],
				#keyPath(Issue.remoteId):         [.restName("id"),                 .restToLocalTransformer(intTransformer)],
				#keyPath(Issue.repository):       [.restName("repository")],
				#keyPath(Issue.title):            [.restName("title")],
				#keyPath(Issue.updateDate):       [.restName("updated_at"),         .restToLocalTransformer(dateTransformer)],
				#keyPath(Issue.zEphemeralDeletionDate): [.localConstant(nil)]
			])
		]
		
		let LabelMapping: [_RESTConvenienceMappingForEntity] = [
			/* /repos/:owner/:repo/labels                <-- Lists all labels in given repository */
			/* /repos/:owner/:repo/labels/:name          <-- Get one label */
			/* /repos/:owner/:repo/issues/:number/labels <-- Lists labels of a given issue */
			.restPath("/repos/|repository.owner.username|/|repository.name|(/issues/|issue.issueNumber|)/labels(/|name|)"),
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				#keyPath(Label.bmoId):     [.restName("id"),          .restToLocalTransformer(intToStrTransformer)],
				#keyPath(Label.color):     [.restName("color"),       .restToLocalTransformer(colorTransformer)],
				#keyPath(Label.descr):     [.restName("description")],
				#keyPath(Label.isDefault): [.restName("default"),     .restToLocalTransformer(boolTransformer)],
				#keyPath(Label.name):      [.restName("name")],
				#keyPath(Label.nodeId):    [.restName("node_id")],
				#keyPath(Label.remoteId):  [.restName("id"),          .restToLocalTransformer(intTransformer)]
			])
		]
		
		let LicenseMapping: [_RESTConvenienceMappingForEntity] = [
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				#keyPath(License.bmoId):  [.restName("key")],
				#keyPath(License.key):    [.restName("key")],
				#keyPath(License.name):   [.restName("name")],
				#keyPath(License.nodeId): [.restName("node_id")]
			])
		]
		
		let RepositoryMapping: [_RESTConvenienceMappingForEntity] = [
			/* /repos/:owner/:repo    <-- Get one repository */
			/* /user/repos            <-- Lists all repositories on which the authenticated user has explicit permission to access */
			/* /users/:username/repos <-- Lists public repositories for the specified user */
			/* /orgs/:org/repos       <-- Lists repositories for the specified org */
			/* /repositories          <-- Lists all public repositories */
			.restPath("/repos/|owner.username|/|name|"),
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				#keyPath(Repository.bmoId):            [.restName("id"),                .restToLocalTransformer(intToStrTransformer)],
				#keyPath(Repository.creationDate):     [.restName("created_at"),        .restToLocalTransformer(dateTransformer)],
				#keyPath(Repository.defaultBranch):    [.restName("default_branch")],
				#keyPath(Repository.descr):            [.restName("description")],
				#keyPath(Repository.forksCount):       [.restName("forks_count"),       .restToLocalTransformer(intTransformer)],
				#keyPath(Repository.fullName):         [.restName("full_name")],
				#keyPath(Repository.hasDownloads):     [.restName("has_downloads"),     .restToLocalTransformer(boolTransformer)],
				#keyPath(Repository.hasIssues):        [.restName("has_issues"),        .restToLocalTransformer(boolTransformer)],
				#keyPath(Repository.hasPages):         [.restName("has_pages"),         .restToLocalTransformer(boolTransformer)],
				#keyPath(Repository.hasWiki):          [.restName("has_wiki"),          .restToLocalTransformer(boolTransformer)],
				#keyPath(Repository.isArchived):       [.restName("archived"),          .restToLocalTransformer(boolTransformer)],
				#keyPath(Repository.isFork):           [.restName("fork"),              .restToLocalTransformer(boolTransformer)],
				#keyPath(Repository.isPrivate):        [.restName("private"),           .restToLocalTransformer(boolTransformer)],
				#keyPath(Repository.latestPushDate):   [.restName("pushed_at"),         .restToLocalTransformer(dateTransformer)],
				#keyPath(Repository.license):          [.restName("license")],
				#keyPath(Repository.name):             [.restName("name")],
				#keyPath(Repository.nodeId):           [.restName("node_id")],
				#keyPath(Repository.openIssuesCount):  [.restName("open_issues_count"), .restToLocalTransformer(intTransformer)],
				#keyPath(Repository.owner):            [.restName("owner")],
				#keyPath(Repository.remoteId):         [.restName("id"),                .restToLocalTransformer(intTransformer)],
				#keyPath(Repository.stargazersCount):  [.restName("stargazers_count"),  .restToLocalTransformer(intTransformer)],
				#keyPath(Repository.topics):           [.restName("topics"),            .restToLocalTransformer(TopicsTransformer())],
				#keyPath(Repository.updateDate):       [.restName("updated_at"),        .restToLocalTransformer(dateTransformer)],
				#keyPath(Repository.watchersCount):    [.restName("subscribers_count"), .restToLocalTransformer(intTransformer)],
				#keyPath(Repository.zDeletionDateInRepositoriesList): [.localConstant(nil)],
				#keyPath(Repository.zEphemeralDeletionDate):          [.localConstant(nil)]
			])
		]
		
		let TopicMapping: [_RESTConvenienceMappingForEntity] = [
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				#keyPath(Topic.bmoId): [.restName("name")],
				#keyPath(Topic.name):  [.restName("name")]
			])
		]
		
		let UserMapping: [_RESTConvenienceMappingForEntity] = [
			/* /users/:username <-- Get one user */
			/* /users           <-- Lists all the users */
			/* /user            <-- Get the authenticated user */
			.restPath("/users(/|username|)"),
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				#keyPath(User.avatarURL):        [.restName("avatar_url"),   .restToLocalTransformer(urlTransformer)],
				#keyPath(User.bmoId):            [.restName("id"),           .restToLocalTransformer(intToStrTransformer)],
				#keyPath(User.company):          [.restName("company")],
				#keyPath(User.creationDate):     [.restName("created_at"),   .restToLocalTransformer(dateTransformer)],
				#keyPath(User.followersCount):   [.restName("followers"),    .restToLocalTransformer(intTransformer)],
				#keyPath(User.followingCount):   [.restName("following"),    .restToLocalTransformer(intTransformer)],
				#keyPath(User.name):             [.restName("name")],
				#keyPath(User.nodeId):           [.restName("node_id")],
				#keyPath(User.publicGistsCount): [.restName("public_gists"), .restToLocalTransformer(intTransformer)],
				#keyPath(User.publicReposCount): [.restName("public_repos"), .restToLocalTransformer(intTransformer)],
				#keyPath(User.remoteId):         [.restName("id"),           .restToLocalTransformer(intTransformer)],
				#keyPath(User.updateDate):       [.restName("updated_at"),   .restToLocalTransformer(dateTransformer)],
				#keyPath(User.username):         [.restName("login")],
				#keyPath(User.zDeletionDateInUsersList): [.localConstant(nil)],
				#keyPath(User.zEphemeralDeletionDate):   [.localConstant(nil)]
			])
		]
		
		return RESTMapper(
			model: dbModel, defaultFieldsKeyName: nil,
			defaultPaginator: paginator,
			convenienceMapping: [
				File.entity().name!: FileMapping,
				FileLanguage.entity().name!: FileLanguageMapping,
				Gist.entity().name!: GistMapping,
				Issue.entity().name!: IssueMapping,
				Label.entity().name!: LabelMapping,
				License.entity().name!: LicenseMapping,
				Repository.entity().name!: RepositoryMapping,
				Topic.entity().name!: TopicMapping,
				User.entity().name!: UserMapping
			]
		)
	}()
	
}
