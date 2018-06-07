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
import RESTUtils



public class GitHubBMOBridge : Bridge {
   
   public typealias DbType = NSManagedObjectContext
   public typealias AdditionalRequestInfoType = AdditionalRESTRequestInfo<NSPropertyDescription>
   
   public typealias UserInfoType = Void
   public typealias MetadataType = Void
   
   public typealias RemoteObjectRepresentationType = [String: Any?]
   public typealias RemoteRelationshipAndMetadataRepresentationType = [[String: Any?]]
   
   public typealias BackOperationType = Operation
   
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
   
}
