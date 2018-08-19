/*
 * Utilities.swift
 * GitHub iOS
 *
 * Created by François Lamboley on 19/08/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

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
