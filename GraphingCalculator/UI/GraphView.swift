//
//  GraphView.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 16.12.21.
//

import Combine
import RealModule
import SwiftUI


struct GraphView: View {
    @Binding var sidebarWidth: Double
    
    @EnvironmentObject var state: GraphState
    
    @State var xAxisIsHovered = false
    @State var yAxisIsHovered = false
    
    @State var mousePosition: Point?
    @State var lastDragLocation: Point?
    
    @State var isDragging = false
    
    
    var body: some View {
        GeometryReader { proxy in
            let size = Size(width: proxy.size.width, height: proxy.size.height)
            
            let (originX, originY) = self.state.canvasCoordinates(from: .zero, forCanvasSize: size)
            
            
            GraphCanvasView(xAxisIsHovered: self.$xAxisIsHovered, yAxisIsHovered: self.$yAxisIsHovered, sidebarWidth: self.$sidebarWidth)
                .onMouseMove { location in
                    self.mousePosition = location
                }
                .regionHover(.init(x: 0, y: originY ?- 4 ?? -8, width: size.width, height: 8), isHovered: self.$xAxisIsHovered)
                .regionHover(.init(x: originX ?- 4 ?? -8, y: 0, width: 8, height: size.height), isHovered: self.$yAxisIsHovered)
                .onScroll { delta in
                    let zoomMultiplier = Double.pow(1.05, -delta)
                            
                    var xZoomMultiplier = 1.0
                    var yZoomMultiplier = 1.0
                    
                    if !self.xAxisIsHovered && !self.yAxisIsHovered {
                        xZoomMultiplier = zoomMultiplier
                        yZoomMultiplier = zoomMultiplier
                    } else {
                        if self.xAxisIsHovered {
                            xZoomMultiplier = zoomMultiplier
                        }
                        if self.yAxisIsHovered {
                            yZoomMultiplier = zoomMultiplier
                        }
                    }
                    
                    guard let mousePosition else {
                        fatalError("Mouse must have entered view to scroll")
                    }
                    
                    let origin = self.state.point(fromCanvasPoint: mousePosition, forCanvasSize: size)
                    
                    self.state.zoom(withXMultiplier: xZoomMultiplier, yMultiplier: yZoomMultiplier, origin: origin)
                }
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            let lastCanvasLocation = self.lastDragLocation ?? .init(gesture.startLocation)
                            let currentCanvasLocation = Point(gesture.location)
                            
                            let lastLocation = self.state.point(fromCanvasPoint: lastCanvasLocation, forCanvasSize: size)
                            let currentLocation = self.state.point(fromCanvasPoint: currentCanvasLocation, forCanvasSize: size)
                            
                            
                            self.state.offsetCenter(byX: lastLocation.x - currentLocation.x, y: lastLocation.y - currentLocation.y)
                            
                            
                            self.lastDragLocation = currentCanvasLocation
                        }
                        .onEnded { gesture in
                            let lastCanvasLocation = self.lastDragLocation ?? .init(gesture.startLocation)
                            let currentCanvasLocation = Point(gesture.location)
                            
                            let lastLocation = self.state.point(fromCanvasPoint: lastCanvasLocation, forCanvasSize: size)
                            let currentLocation = self.state.point(fromCanvasPoint: currentCanvasLocation, forCanvasSize: size)
                            
                            
                            self.state.offsetCenter(byX: lastLocation.x - currentLocation.x, y: lastLocation.y - currentLocation.y)
                            
                            
                            self.lastDragLocation = nil
                        }
                )
        }
    }
}


struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        GraphView(sidebarWidth: .constant(200))
    }
}
