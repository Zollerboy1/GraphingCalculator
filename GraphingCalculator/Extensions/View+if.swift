//
//  View+if.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 10.01.22.
//

import SwiftUI

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool, @ViewBuilder transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}
