/*
 * GitHubBMOBridge.swift
 * GitHub Clients
 *
 * Created by François Lamboley on 07/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation

import BMO
import BMO_CoreData
import BMO_RESTCoreData
import RESTUtils



public class GitHubBMOBridge : Bridge {
	
	public typealias DbType = NSManagedObjectContext
	public typealias AdditionalRequestInfoType = AdditionalRESTRequestInfo<NSPropertyDescription>
	
	public typealias UserInfoType = Void
	public typealias MetadataType = Void
	
	public typealias RemoteObjectRepresentationType = [String: Any?]
	public typealias RemoteRelationshipAndMetadataRepresentationType = [[String: Any?]]
	
	public typealias BackOperationType = Operation
	
	public init(dbModel m: NSManagedObjectModel) {
		dbModel = m
	}
	
	public func createUserInfoObject() -> UserInfoType {
		return ()
	}
	
	public func backOperation(forFetchRequest fetchRequest: DbType.FetchRequestType, additionalInfo: AdditionalRequestInfoType?, userInfo: inout UserInfoType) throws -> Operation? {
		return nil
	}
	
	public func backOperation(forInsertedObject insertedObject: DbType.ObjectType, additionalInfo: AdditionalRequestInfoType?, userInfo: inout UserInfoType) throws -> Operation? {
		return nil
	}
	
	public func backOperation(forUpdatedObject updatedObject: DbType.ObjectType, additionalInfo: AdditionalRequestInfoType?, userInfo: inout UserInfoType) throws -> Operation? {
		return nil
	}
	
	public func backOperation(forDeletedObject deletedObject: DbType.ObjectType, additionalInfo: AdditionalRequestInfoType?, userInfo: inout UserInfoType) throws -> Operation? {
		return nil
	}
	
	public func error(fromFinishedOperation operation: BackOperationType) -> Error? {
		return nil
	}
	
	public func userInfo(fromFinishedOperation operation: BackOperationType, currentUserInfo: UserInfoType) -> UserInfoType {
		return ()
	}
	
	public func bridgeMetadata(fromFinishedOperation operation: BackOperationType, userInfo: UserInfoType) -> MetadataType? {
		return ()
	}
	
	public func remoteObjectRepresentations(fromFinishedOperation operation: BackOperationType, userInfo: UserInfoType) throws -> [RemoteObjectRepresentationType]? {
		return nil
	}
	
	public func mixedRepresentation(fromRemoteObjectRepresentation remoteRepresentation: RemoteObjectRepresentationType, expectedEntity: DbType.EntityDescriptionType, userInfo: UserInfoType) -> MixedRepresentation<DbType.EntityDescriptionType, RemoteRelationshipAndMetadataRepresentationType, UserInfoType>? {
		return nil
	}
	
	public func subUserInfo(forRelationshipNamed relationshipName: String, inEntity entity: DbType.EntityDescriptionType, currentMixedRepresentation: MixedRepresentation<DbType.EntityDescriptionType, RemoteRelationshipAndMetadataRepresentationType, UserInfoType>) -> UserInfoType {
		return ()
	}
	
	public func metadata(fromRemoteRelationshipAndMetadataRepresentation remoteRelationshipAndMetadataRepresentation: RemoteRelationshipAndMetadataRepresentationType, userInfo: UserInfoType) -> MetadataType? {
		return ()
	}
	
	public func remoteObjectRepresentations(fromRemoteRelationshipAndMetadataRepresentation remoteRelationshipAndMetadataRepresentation: RemoteRelationshipAndMetadataRepresentationType, userInfo: UserInfoType) -> [RemoteObjectRepresentationType]? {
		return nil
	}
	
	public func relationshipMergeType(forRelationshipNamed relationshipName: String, inEntity entity: DbType.EntityDescriptionType, currentMixedRepresentation: MixedRepresentation<DbType.EntityDescriptionType, RemoteRelationshipAndMetadataRepresentationType, UserInfoType>) -> DbRepresentationRelationshipMergeType<DbType.EntityDescriptionType, DbType.ObjectType> {
		return .replace
	}
	
	let dbModel: NSManagedObjectModel
	
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
				"bmoId":       [.restName("id")],
				"filename":    [.restName("filename")],
				"isTruncated": [.restName("truncated"), .restToLocalTransformer(boolTransformer)],
				"language":    [.restName("language")],
				"mimeType":    [.restName("type")],
				"rawURL":      [.restName("raw_url"),   .restToLocalTransformer(urlTransformer)],
				"size":        [.restName("size"),      .restToLocalTransformer(intTransformer)]
			])
		]
		
		let FileLanguageMapping: [_RESTConvenienceMappingForEntity] = [
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				"bmoId": [.restName("name")],
				"name":  [.restName("name")]
			])
		]
		
		let GistMapping: [_RESTConvenienceMappingForEntity] = [
			.restPath("/gists"),
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				"bmoId":        [.restName("id")],
				"creationDate": [.restName("created_at"),   .restToLocalTransformer(dateTransformer)],
				"descr":        [.restName("description")],
				"files":        [                           .restToLocalTransformer(FilesTransformer())],
				"gitPullURL":   [.restName("git_pull_url"), .restToLocalTransformer(urlTransformer)],
				"gitPushURL":   [.restName("git_push_url"), .restToLocalTransformer(urlTransformer)],
				"isPublic":     [.restName("public"),       .restToLocalTransformer(boolTransformer)],
				"isTruncated":  [.restName("truncated"),    .restToLocalTransformer(boolTransformer)],
				"nodeId":       [.restName("nodeId")],
				"owner":        [.restName("owner")],
				"remoteId":     [.restName("id")],
				"updateDate":   [.restName("updated_at"),   .restToLocalTransformer(dateTransformer)]
			])
		]
		
		let IssueMapping: [_RESTConvenienceMappingForEntity] = [
			.restPath("/issues"),
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				"activeLockReason": [.restName("active_lock_reason")],
				"assignees":        [.restName("assignees")],
				"bmoId":            [.restName("id"),                 .restToLocalTransformer(intToStrTransformer)],
				"closeDate":        [.restName("closed_at"),          .restToLocalTransformer(dateTransformer)],
				"commentsCount":    [.restName("comments"),           .restToLocalTransformer(intTransformer)],
				"creationDate":     [.restName("created_at"),         .restToLocalTransformer(dateTransformer)],
				"isLocked":         [.restName("locked"),             .restToLocalTransformer(boolTransformer)],
				"labels":           [.restName("labels")],
				"nodeId":           [.restName("node_id")],
				"remoteId":         [.restName("id"),                 .restToLocalTransformer(intTransformer)],
				"repository":       [.restName("repository")],
				"updateDate":       [.restName("updated_at"),         .restToLocalTransformer(dateTransformer)]
			])
		]
		
		let LabelMapping: [_RESTConvenienceMappingForEntity] = [
			.restPath("/repos/|repository.owner|/|repository|/labels"),
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				"bmoId":     [.restName("id"),          .restToLocalTransformer(intToStrTransformer)],
				"color":     [.restName("color"),       .restToLocalTransformer(colorTransformer)],
				"descr":     [.restName("description")],
				"isDefault": [.restName("default"),     .restToLocalTransformer(boolTransformer)],
				"name":      [.restName("name")],
				"nodeId":    [.restName("node_id")],
				"remoteId":  [.restName("id"),          .restToLocalTransformer(intTransformer)]
			])
		]
		
		let LicenseMapping: [_RESTConvenienceMappingForEntity] = [
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				"bmoId":  [.restName("key")],
				"key":    [.restName("key")],
				"name":   [.restName("name")],
				"nodeId": [.restName("node_id")]
			])
		]
		
		let RepositoryMapping: [_RESTConvenienceMappingForEntity] = [
			.restPath("/user(s/|owner.name|/)repos"),
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				"bmoId":            [.restName("id"),                .restToLocalTransformer(intToStrTransformer)],
				"creationDate":     [.restName("created_at"),        .restToLocalTransformer(dateTransformer)],
				"defaultBranch":    [.restName("default_branch")],
				"descr":            [.restName("description")],
				"forksCount":       [.restName("forks_count"),       .restToLocalTransformer(intTransformer)],
				"fullName":         [.restName("full_name")],
				"hasDownloads":     [.restName("has_downloads"),     .restToLocalTransformer(boolTransformer)],
				"hasIssues":        [.restName("has_issues"),        .restToLocalTransformer(boolTransformer)],
				"hasPages":         [.restName("has_pages"),         .restToLocalTransformer(boolTransformer)],
				"hasWiki":          [.restName("has_wiki"),          .restToLocalTransformer(boolTransformer)],
				"isArchived":       [.restName("archived"),          .restToLocalTransformer(boolTransformer)],
				"isFork":           [.restName("fork"),              .restToLocalTransformer(boolTransformer)],
				"isPrivate":        [.restName("private"),           .restToLocalTransformer(boolTransformer)],
				"latestPushDate":   [.restName("pushed_at"),         .restToLocalTransformer(dateTransformer)],
				"license":          [.restName("license")],
				"name":             [.restName("name")],
				"nodeId":           [.restName("node_id")],
				"openIssuesCount":  [.restName("open_issues_count"), .restToLocalTransformer(intTransformer)],
				"owner":            [.restName("owner")],
				"remoteId":         [.restName("id"),                .restToLocalTransformer(intTransformer)],
				"stargazersCount":  [.restName("stargazers_count"),  .restToLocalTransformer(intTransformer)],
				"subscribersCount": [.restName("subscribers_count"), .restToLocalTransformer(intTransformer)],
				"topics":           [.restName("topics"),            .restToLocalTransformer(TopicsTransformer())],
				"updateDate":       [.restName("updated_at"),        .restToLocalTransformer(dateTransformer)],
				"watchersCount":    [.restName("watchers_count"),    .restToLocalTransformer(intTransformer)]
			])
		]
		
		let TopicMapping: [_RESTConvenienceMappingForEntity] = [
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				"bmoId": [.restName("name")],
				"name":  [.restName("name")]
			])
		]
		
		let UserMapping: [_RESTConvenienceMappingForEntity] = [
			.restPath("/users(/|id|)"),
			.uniquingPropertyName("bmoId"),
			.propertiesMapping([
				"avatarURL":        [.restName("avatar_url"),   .restToLocalTransformer(urlTransformer)],
				"bmoId":            [.restName("id"),           .restToLocalTransformer(intToStrTransformer)],
				"company":          [.restName("company")],
				"creationDate":     [.restName("created_at"),   .restToLocalTransformer(dateTransformer)],
				"followersCount":   [.restName("followers"),    .restToLocalTransformer(intTransformer)],
				"followingCount":   [.restName("following"),    .restToLocalTransformer(intTransformer)],
				"name":             [.restName("name")],
				"nodeId":           [.restName("node_id")],
				"publicGistsCount": [.restName("public_gists"), .restToLocalTransformer(intTransformer)],
				"publicReposCount": [.restName("public_repos"), .restToLocalTransformer(intTransformer)],
				"remoteId":         [.restName("id"),           .restToLocalTransformer(intTransformer)],
				"updateDate":       [.restName("updated_at"),   .restToLocalTransformer(dateTransformer)],
				"usename":          [.restName("login")]
			])
		]
		
		return RESTMapper(
			model: dbModel,
			defaultPaginator: RESTOffsetLimitPaginator(),
			convenienceMapping: [
				"File": FileMapping,
				"FileLanguage": FileLanguageMapping,
				"Gist": GistMapping,
				"Issue": IssueMapping,
				"Label": LabelMapping,
				"License": LicenseMapping,
				"Repository": RepositoryMapping,
				"Topic": TopicMapping,
				"User": UserMapping
			]
		)
	}()
	
}
