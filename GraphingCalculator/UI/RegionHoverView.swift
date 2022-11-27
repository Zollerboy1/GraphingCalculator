//
//  RegionHoverView.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 10.01.22.
//

import SwiftUI


extension View {
    func regionHover(_ region: Rect, isHovered: Binding<Bool>) -> RegionHoverView<Self> {
        .init(region: region, isHovered: isHovered) { self }
    }
}

extension View where Self: MouseTrackingViewProtocol {
    func regionHover(_ region: Rect, isHovered: Binding<Bool>) -> RegionHoverView<Self.Content> {
        .init(region: region, isHovered: isHovered, wrapped: self)
    }
}


struct RegionHoverView<Content>: View, MouseTrackingViewProtocol where Content: View {
    let content: () -> Content
    
    let onMove: ((Point) -> ())?
    let onEnter: (() -> ())?
    let onExit: (() -> ())?
    let onScroll: ((Double) -> ())?
    
    
    init(region: Rect, isHovered: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        
        self.onMove = { location in
            if region.contains(location) {
                if !isHovered.wrappedValue {
                    isHovered.wrappedValue = true
                }
            } else if isHovered.wrappedValue {
                isHovered.wrappedValue = false
            }
        }
        
        self.onEnter = {}
        
        self.onExit = {
            if isHovered.wrappedValue {
                isHovered.wrappedValue = false
            }
        }
        
        self.onScroll = { _ in }
    }
    
    fileprivate init<Wrapped>(region: Rect, isHovered: Binding<Bool>, wrapped: Wrapped) where Wrapped: MouseTrackingViewProtocol, Wrapped.Content == Content {
        self.content = wrapped.content
        
        self.onMove = { location in
            wrapped.onMove?(location)
            
            if region.contains(location) {
                if !isHovered.wrappedValue {
                    isHovered.wrappedValue = true
                }
            } else if isHovered.wrappedValue {
                isHovered.wrappedValue = false
            }
        }
        
        self.onEnter = wrapped.onEnter
        
        self.onExit = {
            wrapped.onExit?()
            
            if isHovered.wrappedValue {
                isHovered.wrappedValue = false
            }
        }
        
        self.onScroll = wrapped.onScroll
    }
}
