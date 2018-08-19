/*
 * NSManagedObject+RESTPath.swift
 * GitHub Clients
 *
 * Created by François Lamboley on 18/08/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation

import RESTUtils



/* Directly from BMO. See the CoreData+RESTPath file. */
extension NSManagedObject : RESTPathKeyResovable {
	
	public func restPathObject(for key: String) -> Any? {
		guard !key.isEmpty else {return self}
		guard entity.propertiesByName.keys.contains(key) else {return nil}
		return value(forKey: key)
	}
	
}

extension NSNumber : RESTPathStringConvertible {
	
	public var stringValueForRESTPath: String {
		return self.stringValue
	}
	
}
