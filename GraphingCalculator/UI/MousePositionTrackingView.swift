//
//  MousePositionTrackingView.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 23.11.22.
//

import SwiftUI


extension View {
    func onMouseMove(perform action: @escaping (_ location: Point) -> ()) -> MousePositionTrackingView<Self> {
        .init(perform: action) { self }
    }
}


extension View where Self: MouseTrackingViewProtocol {
    func onMouseMove(perform action: @escaping (_ location: Point) -> ()) -> MousePositionTrackingView<Self.Content> {
        .init(perform: action, wrapped: self)
    }
}


struct MousePositionTrackingView<Content>: MouseTrackingViewProtocol where Content: View {
    let content: () -> Content
    
    let onMove: ((Point) -> ())?
    let onEnter: (() -> ())?
    let onExit: (() -> ())?
    let onScroll: ((Double) -> ())?
    
    
    init(perform action: @escaping (_ location: Point) -> (), @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        
        self.onMove = action
        
        self.onEnter = nil
        self.onExit = nil
        self.onScroll = nil
    }
    
    fileprivate init<Wrapped>(perform action: @escaping (_ location: Point) -> (), wrapped: Wrapped) where Wrapped: MouseTrackingViewProtocol, Wrapped.Content == Content {
        self.content = wrapped.content
        
        self.onMove = { location in
            wrapped.onMove?(location)
            
            action(location)
        }
        
        self.onEnter = wrapped.onEnter
        self.onExit = wrapped.onExit
        self.onScroll = wrapped.onScroll
    }
}
