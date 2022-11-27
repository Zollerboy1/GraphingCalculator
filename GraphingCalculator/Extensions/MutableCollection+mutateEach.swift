//
//  MutableCollection+mutateEach.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 27.11.22.
//

extension MutableCollection {
    @inlinable
    public mutating func mutateEach(
        _ body: (inout Element) throws -> Void
    ) rethrows {
        var index = self.startIndex
        while index != self.endIndex {
            try body(&self[index])
            self.formIndex(after: &index)
        }
    }
}
