//
//  MouseScrollTrackingView.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 13.01.22.
//

import SwiftUI


extension View {
    func onScroll(perform action: @escaping (_ delta: Double) -> ()) -> MouseScrollTrackingView<Self> {
        .init(perform: action) { self }
    }
}


extension View where Self: MouseTrackingViewProtocol {
    func onScroll(perform action: @escaping (_ delta: Double) -> ()) -> MouseScrollTrackingView<Self.Content> {
        .init(perform: action, wrapped: self)
    }
}


struct MouseScrollTrackingView<Content>: MouseTrackingViewProtocol where Content: View {
    let content: () -> Content
    
    let onMove: ((Point) -> ())?
    let onEnter: (() -> ())?
    let onExit: (() -> ())?
    let onScroll: ((Double) -> ())?
    
    
    init(perform action: @escaping (_ delta: Double) -> (), @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        
        self.onMove = nil
        self.onEnter = nil
        self.onExit = nil
        
        self.onScroll = action
    }
    
    fileprivate init<Wrapped>(perform action: @escaping (_ delta: Double) -> (), wrapped: Wrapped) where Wrapped: MouseTrackingViewProtocol, Wrapped.Content == Content {
        self.content = wrapped.content
        
        self.onMove = wrapped.onMove
        self.onEnter = wrapped.onEnter
        self.onExit = wrapped.onExit
        
        self.onScroll = { delta in
            wrapped.onScroll?(delta)
            
            action(delta)
        }
    }
}
