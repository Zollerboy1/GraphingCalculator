//
//  Rect.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 17.12.21.
//

import Foundation


struct Rect: Hashable {
    let origin: Point
    let size: Size
    
    init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }
    
    init(x: Double, y: Double, width: Double, height: Double) {
        self.init(origin: .init(x: x, y: y), size: .init(width: width, height: height))
    }
    
    init(size: Size) {
        self.init(origin: .zero, size: size)
    }
    
    init(width: Double, height: Double) {
        self.init(size: .init(width: width, height: height))
    }
    
    
    var minX: Double { self.origin.x }
    var minY: Double { self.origin.y }
    
    var maxX: Double { self.origin.x + self.size.width }
    var maxY: Double { self.origin.y + self.size.height }
    
    
    func contains(_ point: Point) -> Bool {
        return self.minX <= point.x
            && self.minY <= point.y
            && self.maxX >= point.x
            && self.maxY >= point.y
    }
    
    func relativeXCoordinate(from x: Double) -> Double? {
        guard self.minX <= x && self.maxX >= x else { return nil }
        
        return (x - self.minX) / self.size.width
    }
    
    func relativeYCoordinate(from y: Double) -> Double? {
        guard self.minY <= y && self.maxY >= y else { return nil }
        
        return (y - self.minY) / self.size.height
    }
    
    func relativeCoordinates(from point: Point) -> Point? {
        guard let relativeX = self.relativeXCoordinate(from: point.x),
              let relativeY = self.relativeYCoordinate(from: point.y) else { return nil }
        
        return .init(x: relativeX, y: relativeY)
    }
    
    func absoluteXCoordinate(from relativeX: Double) -> Double {
        (relativeX * self.size.width) + self.minX
    }
    
    func absoluteYCoordinate(from relativeY: Double) -> Double {
        (relativeY * self.size.height) + self.minY
    }
}

extension Rect {
    init(_ cgRect: CGRect) {
        self.init(origin: .init(cgRect.origin), size: .init(cgRect.size))
    }
    
    var cgRect: CGRect {
        .init(origin: self.origin.cgPoint, size: self.size.cgSize)
    }
}
