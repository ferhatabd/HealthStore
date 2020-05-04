//
//  File.swift
//  
//
//  Created by Ferhat Abdullahoglu on 4.05.2020.
//

import Foundation
import os.log

internal protocol Loggable {
    
    /// Logger
    var logger: OSLog { get set }
    
    var domain: String { get }
}

extension Loggable {
    
    func log(_ message: String, type: OSLogType = .default) {
        os_log("%@", type: type, message)
    }
}
