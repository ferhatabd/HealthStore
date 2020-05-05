//
//  File.swift
//  
//
//  Created by Ferhat Abdullahoglu on 5.05.2020.
//

import Foundation

/// Defines a standard Workout skeleton
public protocol Workout {
    
    /// Each workout might have different types regarding
    /// the actual data they have
    ///
    associatedtype UnitType
    
    /// start date
    var start: Date { get set }
    
    /// end date
    var end: Date { get set }
    
    /// Duration of the workout
    var duration: TimeInterval { get }
    
    /// Actual workout gem
    var data: UnitType { get set }
}


public extension Workout {
    
    /// Duration of the workout
    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
    
}
