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



func nullify(property: NSAttributeDescription, inInstancesOf entity: NSEntityDescription, context: NSManagedObjectContext) {
	let fr = NSFetchRequest<NSManagedObject>()
	fr.entity = entity
	fr.predicate = NSPredicate(format: "%K != NULL", property.name)
	if let r = try? context.fetch(fr) {
		for o in r {o.setValue(nil, forKey: property.name)}
		try? context.save()
	}
}
