//
//  FloatingPoint+isInteger.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 24.11.22.
//

extension FloatingPoint {
    var isInteger: Bool {
        self.isApproximatelyEqual(to: self.rounded(.toNearestOrEven))
    }
}
