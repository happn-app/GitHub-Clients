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
