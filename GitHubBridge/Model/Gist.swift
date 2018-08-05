/*
 * Gist.swift
 * GitHub Clients
 *
 * Created by François Lamboley on 05/08/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation

import KVObserver



@objc(Gist)
public class Gist : NSManagedObject {
	
	/* ***************************
	   MARK: - Core Data Overrides
	   *************************** */
	
	public override func awakeFromFetch() {
		/* This is also called when a fault is fulfilled (fulfilling a fault is a
		 * fetch).
		 * Always DO call super's implementation *first*.
		 *
		 * Context's changes processing is disabled in this method. This also
		 * means inverse relationship are not set automatically when relationships
		 * are modified in this method. */
		super.awakeFromFetch()
		
		if observingIdForFiles == nil {
			observingIdForFiles = kvObserver.observe(object: self, keyPath: #keyPath(Gist.files), kvoOptions: [.initial], dispatchType: .direct, handler: { [weak self] in self?.processFilesKVOChange($0) })
		}
	}
	
	public override func awakeFromInsert() {
		/* Use primitive accessors to change properties values in this method.
		 * Always DO call super's implementation first. */
		super.awakeFromInsert()
		
		if observingIdForFiles == nil {
			observingIdForFiles = kvObserver.observe(object: self, keyPath: #keyPath(Gist.files), kvoOptions: [], dispatchType: .direct, handler: { [weak self] in self?.processFilesKVOChange($0) })
		}
	}
	
	public override func willTurnIntoFault() {
		observingIdForFiles.map{ kvObserver.stopObserving(id: $0) }
		observingIdForFiles = nil
		
		observingIdForFirstFile.map{ kvObserver.stopObserving(id: $0) }
		observingIdForFirstFile = nil
		
		super.willTurnIntoFault()
	}
	
	/* *******************
	   MARK - KVO-Handling
	   ******************* */
	
	private func processFilesKVOChange(_ changes: [NSKeyValueChangeKey: Any]?) {
		let firstFile = files?.firstObject as! File?
		guard firstFile != observedFile else {return}
		
		observingIdForFirstFile.map{ kvObserver.stopObserving(id: $0) }
		
		observedFile = firstFile
		observingIdForFirstFile = firstFile.flatMap{ kvObserver.observe(object: $0, keyPath: #keyPath(File.filename), kvoOptions: [.initial], dispatchType: .direct, handler: { [weak self] in self?.processFirstFileKVOChange($0) }) }
	}
	
	private func processFirstFileKVOChange(_ changes: [NSKeyValueChangeKey: Any]?) {
		firstFileName = observedFile?.filename
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	let kvObserver = KVObserver()
	
	private var observingIdForFiles: KVObserver.ObservingId?
	
	private var observedFile: File?
	private var observingIdForFirstFile: KVObserver.ObservingId?
	
}
