//
//  MouseTrackingViewProtocol.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 13.01.22.
//

import SwiftUI


protocol MouseTrackingViewProtocol: View {
    associatedtype Content: View
    
    var content: () -> Content { get }
    
    var onMove: ((Point) -> ())? { get }
    var onEnter: (() -> ())? { get }
    var onExit: (() -> ())? { get }
    var onScroll: ((Double) -> ())? { get }
}


extension MouseTrackingViewProtocol {
    var body: some View {
        self.content().trackingMouse(onMove: self.onMove ?? { _ in },
                                     onEnter: self.onEnter ?? {},
                                     onExit: self.onExit ?? {},
                                     onScroll: self.onScroll ?? { _ in })
    }
}
