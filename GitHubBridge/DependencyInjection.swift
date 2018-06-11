/*
 * DependencyInjection.swift
 * GitHub Clients
 *
 * Created by François Lamboley on 10/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation
import os.log



public struct DependencyInjection {
	
	public var log: OSLog? = .default
	
	public var apiRoot = URL(string: "https://api.github.com/")!
	
}

public var di = DependencyInjection()
