//
//  RangeReplaceableCollection+extract.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 27.11.22.
//

import Algorithms

extension RangeReplaceableCollection {
    @inlinable
    public mutating func extractAll(
        where shouldBeExtracted: (Element) throws -> Bool
    ) rethrows -> Self {
        var extracted = Self()
        
        self = try self.filter {
            let shouldBeRemoved = try shouldBeExtracted($0)
            
            if shouldBeRemoved {
                extracted.append($0)
            }
            
            return !shouldBeRemoved
        }
        
        return extracted
    }
    
    @inlinable
    public mutating func extractAllMapped<T>(
        where attemptTransform: (Element) throws -> T?
    ) rethrows -> [T] {
        var extracted: [T] = []
        
        self = try self.filter {
            if let transformed = try attemptTransform($0) {
                extracted.append(transformed)
                return false
            } else {
                return true
            }
        }
        
        return extracted
    }
    
    
    @inlinable
    public mutating func extractSubrange(_ bounds: Range<Index>) -> Self {
        let extracted = Self(self[bounds])
        self.removeSubrange(bounds)
        return extracted
    }
    
    @inlinable
    public mutating func extractSubrange<R: RangeExpression>(
        _ bounds: R
    ) -> Self where R.Bound == Index {
        self.extractSubrange(bounds.relative(to: self))
    }
    
    
    @inlinable
    public mutating func extractFirst(_ k: Int) -> Self {
        guard k != 0 else {
            return Self()
        }
        
        precondition(k >= 0, "Number of elements to remove should be non-negative")
        precondition(self.count >= k,
                     "Can't remove more items from a collection than it has")
        
        let end = self.index(startIndex, offsetBy: k)
        let subrange = self.startIndex..<end
        let extracted = Self(self[subrange])
        
        self.removeSubrange(subrange)
        return extracted
    }
}

extension RangeReplaceableCollection where Self: MutableCollection {
    @inlinable
    public mutating func extractAll(
        where shouldBeExtracted: (Element) throws -> Bool
    ) rethrows -> Self {
        let suffixStart = try self.stablePartition(by: shouldBeExtracted)
        return self.extractSubrange(suffixStart...)
    }
}

extension RangeReplaceableCollection where Self: BidirectionalCollection {
    @inlinable
    public mutating func extractLast(_ k: Int) -> Self {
        guard k != 0 else {
            return Self()
        }
        
        precondition(k > 0, "Number of elements to remove should be non-negative")
        precondition(self.count >= k,
                     "Can't remove more items from a collection than it contains")
        
        let end = self.endIndex
        let subrange = self.index(end, offsetBy: -k)..<end
        let extracted = Self(self[subrange])
        
        if self._customRemoveLast(k) {
            return extracted
        }
        
        self.removeSubrange(subrange)
        return extracted
    }
}
