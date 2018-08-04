/*
 * GitHubTransformers.swift
 * GitHub Clients
 *
 * Created by François Lamboley on 07/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



class IntToStringTransformer : ValueTransformer {
	
	override public class func allowsReverseTransformation() -> Bool {
		return false
	}
	
	override public class func transformedValueClass() -> AnyClass {
		return NSString.self
	}
	
	override func transformedValue(_ value: Any?) -> Any? {
		return (value as? Int).flatMap{ String($0) }
	}
	
}


class FilesTransformer : ValueTransformer {
	
	override public class func allowsReverseTransformation() -> Bool {
		return false
	}
	
	override public class func transformedValueClass() -> AnyClass {
		return NSArray.self
	}
	
	override func transformedValue(_ value: Any?) -> Any? {
		guard let value  = value          as? [String: Any?]           else {return nil}
		guard let gistId = value["id"]    as? String                   else {return nil}
		guard let files  = value["files"] as? [String: [String: Any?]] else {return nil}
		
		var ret = [[String: Any?]]()
		for (filename, var fileinfo) in files {
			fileinfo["id"] = gistId + " - " + filename
			fileinfo["filename"] = filename
			ret.append(fileinfo)
		}
		return ret
	}
	
}


class TopicsTransformer : ValueTransformer {
	
	override public class func allowsReverseTransformation() -> Bool {
		return false
	}
	
	override public class func transformedValueClass() -> AnyClass {
		return NSArray.self
	}
	
	override func transformedValue(_ value: Any?) -> Any? {
		return (value as? [String])?.map{ ["name": $0] }
	}
	
}
