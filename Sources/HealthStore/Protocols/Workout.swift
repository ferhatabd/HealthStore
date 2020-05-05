//
//  File.swift
//  
//
//  Created by Ferhat Abdullahoglu on 5.05.2020.
//

import Foundation

/// Defines a standard Workout skeleton
public protocol Workout {
    
    /// start date
    var start: Date { get set }
    
    /// end date
    var end: Date { get set }
    
    /// Duration of the workout
    var duration: TimeInterval { get }
    
}


public extension Workout {
    
    /// Duration of the workout
    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
    
}
