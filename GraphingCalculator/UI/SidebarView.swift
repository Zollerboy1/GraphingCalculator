//
//  SidebarView.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 16.12.21.
//

import SwiftUI


struct SidebarView: View {
    private enum DragState {
        case none
        case hovered
        case hoveredOnlyRight
        case hoveredOnlyLeft
        case dragging
        case draggingOnlyRight
        case draggingOnlyLeft
    }
    
    private static let minWidth = 200.0
    private static let maxWidth = 500.0
    
    
    @Binding var width: Double
    
    @EnvironmentObject private var state: GraphState
    
    @State private var isHovered = false
    @State private var dragState = DragState.none {
        didSet {
            switch (oldValue, self.dragState) {
            case let (old, new) where old == new:
                break
            case (_, .none):
                NSCursor.pop()
            case (.none, .hovered), (.none, .dragging):
                NSCursor.resizeLeftRight.push()
            case (.none, .hoveredOnlyRight), (.none, .draggingOnlyRight):
                NSCursor.resizeRight.push()
            case (.none, .hoveredOnlyLeft), (.none, .draggingOnlyLeft):
                NSCursor.resizeLeft.push()
            case (_, .hovered), (_, .dragging):
                NSCursor.resizeLeftRight.set()
            case (_, .hoveredOnlyRight), (_, .draggingOnlyRight):
                NSCursor.resizeRight.set()
            case (_, .hoveredOnlyLeft), (_, .draggingOnlyLeft):
                NSCursor.resizeLeft.set()
            }
        }
    }
    
    
    var body: some View {
        HStack(spacing: 0) {
            List {
                ForEach(self.$state.declarationStrings.enumerated(), id: \.offset) { index, declarationStringBinding in
                    DeclarationView(index: index, string: declarationStringBinding)
                }
            }
            .listStyle(.sidebar)
            .frame(width: self.width)
            .background(VisualEffectView(material: .toolTip, blendingMode: .behindWindow))
            Rectangle()
                .size(width: 0.5, height: .infinity)
                .fill(self.dragState == .none ? .gray : .white)
                .contentShape(Rectangle().inset(by: -4))
                .onHover { isHovered in
                    self.isHovered = isHovered
                    
                    if isHovered {
                        if self.width.isApproximatelyEqual(to: Self.minWidth) {
                            if self.dragState == .none || self.dragState == .hovered || self.dragState == .hoveredOnlyLeft {
                                self.dragState = .hoveredOnlyRight
                            }
                        } else if self.width.isApproximatelyEqual(to: Self.maxWidth) {
                            if self.dragState == .none || self.dragState == .hovered || self.dragState == .hoveredOnlyRight {
                                self.dragState = .hoveredOnlyLeft
                            }
                        } else {
                            if self.dragState == .none || self.dragState == .hoveredOnlyRight || self.dragState == .hoveredOnlyLeft {
                                self.dragState = .hovered
                            }
                        }
                    } else {
                        if self.dragState == .hovered || self.dragState == .hoveredOnlyRight || self.dragState == .hoveredOnlyLeft {
                            self.dragState = .none
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            self.width = min(max(self.width + gesture.translation.width, Self.minWidth), Self.maxWidth)
                            
                            if self.width.isApproximatelyEqual(to: Self.minWidth) {
                                self.dragState = .draggingOnlyRight
                            } else if self.width.isApproximatelyEqual(to: Self.maxWidth) {
                                self.dragState = .draggingOnlyLeft
                            } else {
                                self.dragState = .dragging
                            }
                        }
                        .onEnded { _ in
                            if self.isHovered {
                                if self.width.isApproximatelyEqual(to: Self.minWidth) {
                                    self.dragState = .hoveredOnlyRight
                                } else if self.width.isApproximatelyEqual(to: Self.maxWidth) {
                                    self.dragState = .hoveredOnlyLeft
                                } else {
                                    self.dragState = .hovered
                                }
                            } else {
                                self .dragState = .none
                            }
                        }
                )
        }
        .frame(width: self.width + 4.5)
    }
}


struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(width: .constant(400))
    }
}
