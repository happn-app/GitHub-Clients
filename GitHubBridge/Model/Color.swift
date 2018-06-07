/*
 * Color.swift
 * GitHub Clients
 *
 * Created by François Lamboley on 07/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation

#if os(OSX)
	import AppKit
	public typealias Color = NSColor
#else
	import UIKit
	public typealias Color = UIColor
#endif
