//
//  Point.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 17.12.21.
//

import Foundation


struct Point: Hashable, CustomStringConvertible {
    let x, y: Double
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    
    static var zero: Point { .init(x: 0, y: 0) }
    
    
    func offset(byX xOffset: Double, y yOffset: Double) -> Point {
        .init(x: self.x + xOffset, y: self.y + yOffset)
    }
    
    
    var description: String {
        "(\(self.x), \(self.y))"
    }
}

extension Point {
    init(_ cgPoint: CGPoint) {
        self.init(x: cgPoint.x, y: cgPoint.y)
    }
    
    var cgPoint: CGPoint {
        .init(x: self.x, y: self.y)
    }
}
