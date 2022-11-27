//
//  Size.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 17.12.21.
//

import Foundation


struct Size: Hashable, CustomStringConvertible {
    let width, height: Double
    
    init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
    
    
    static var zero: Size { .init(width: 0, height: 0) }
    
    
    var description: String {
        "(\(self.width), \(self.height))"
    }
}

extension Size {
    init(_ cgSize: CGSize) {
        self.init(width: cgSize.width, height: cgSize.height)
    }
    
    var cgSize: CGSize {
        .init(width: self.width, height: self.height)
    }
}
