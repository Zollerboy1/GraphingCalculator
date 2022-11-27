//
//  GraphState.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 16.12.21.
//

import RealModule
import SwiftUI


class GraphState: ObservableObject {
    private static let defaultFunctionColors: [Color] = [
        .red,
        .green,
        .blue,
        .orange,
        .purple,
        .yellow
    ]
    
    
    private(set) var centerPoint = Point.zero
    
    private var _cachedCanvasSize = Size.zero
    private var cachedCanvasSize: Size {
        get {
            _cachedCanvasSize
        }
        set {
            _cachedCanvasSize = newValue
            self.recomputeVisibleRect()
        }
    }
    
    private var cachedVisibleRect = Rect(size: .zero)
    
    private(set) var xZoomLevel = 1.0
    private(set) var yZoomLevel = 1.0
    private(set) var xRangeMultiplier = 1.0
    
    
    private var declarationParserTask: Task<Void, Never>?
    
    private var declarationStringStorage = [""]
    var declarationStrings: [String] {
        get {
            self.declarationStringStorage
        }
        set {
            if newValue != self.declarationStringStorage {
                let oldStrings = self.declarationStringStorage
                
                var newValue = newValue
                
                if newValue.last != "" {
                    newValue.append("")
                }
                
                self.objectWillChange.send()
                
                self.declarationStringStorage = newValue
                
                
                if let oldTask = self.declarationParserTask {
                    oldTask.cancel()
                }

                let newStrings = newValue
                let oldDeclarations = self.declarations

                self.declarationParserTask = Task.detached {
                    var declarationChanged = false
                    var availableFunctionColors = Self.defaultFunctionColors

                    let context = SimplificationContext()

                    let newDeclarations = newStrings.enumerated().map { i, newString -> (Declaration, (Color, Bool)?)? in
                        let declaration: Declaration?

                        if !declarationChanged && i < oldDeclarations.count && i < oldStrings.count && oldStrings[i] == newString,
                           let oldDeclaration = oldDeclarations[i] {
                            oldDeclaration.0.add(toContext: context)
                            declaration = oldDeclaration.0
                        } else {
                            declaration = .init(parsedFrom: newString, withContext: context)
                            declarationChanged = true
                        }
                        
                        let color: (Color, Bool)?
                        if case .function = declaration?.storage {
                            if i < oldDeclarations.count,
                               let previousColor = oldDeclarations[i]?.1, previousColor.1 {
                                color = previousColor
                            } else {
                                if availableFunctionColors.isEmpty {
                                    availableFunctionColors = Self.defaultFunctionColors
                                }
                                
                                color = (availableFunctionColors.remove(at: 0), false)
                            }
                        } else {
                            color = nil
                        }

                        if let declaration = declaration {
                            return (declaration, color)
                        } else {
                            return nil
                        }
                    }

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.declarations = newDeclarations
                    }
                }
            }
        }
    }
    
    @Published var declarations = [(Declaration, (Color, Bool)?)?]()
    
    
    private(set) var gridResolution = (x: 1, y: 1)
    
    
    @inline(__always)
    private func transaction<R>(publishChange: Bool = true, perform action: () throws -> R) rethrows -> R {
        if publishChange {
            self.objectWillChange.send()
        }
        
        let result = try action()
        
        self.gridResolution.x = Int(Double.exp2((self.xZoomLevel.rounded(.up) / 5.0).rounded(.down)))
        self.gridResolution.y = Int(Double.exp2((self.yZoomLevel.rounded(.up) / 5.0).rounded(.down)))
        self.recomputeVisibleRect()
        
        return result
    }
    
    
    func offsetCenter(byX xOffset: Double, y yOffset: Double) {
        self.transaction {
            self.centerPoint = self.centerPoint.offset(byX: xOffset, y: yOffset)
        }
    }
    
    func zoom(withXMultiplier xMultiplier: Double, yMultiplier: Double, origin: Point) {
        self.transaction {
            let nextXZoomLevel = self.xZoomLevel * xMultiplier
            
            if nextXZoomLevel >= 0.1 && nextXZoomLevel <= 20 {
                let xOffset = self.centerPoint.x - origin.x
                let zoomedXOffset = xOffset / self.xZoomLevel * nextXZoomLevel
                
                self.centerPoint = .init(x: origin.x + zoomedXOffset, y: self.centerPoint.y)
                
                self.xZoomLevel = nextXZoomLevel
            }
            
            
            let nextYZoomLevel = self.yZoomLevel * yMultiplier
            
            if nextYZoomLevel >= 0.1 && nextYZoomLevel <= 20 {
                let yOffset = self.centerPoint.y - origin.y
                let zoomedYOffset = yOffset / self.yZoomLevel * nextYZoomLevel
                
                self.centerPoint = .init(x: self.centerPoint.x, y: origin.y + zoomedYOffset)
                
                self.yZoomLevel = nextYZoomLevel
            }
        }
    }
    
    
    func visibleRect(forCanvasSize canvasSize: Size) -> Rect {
        guard self._cachedCanvasSize != canvasSize else {
            return self.cachedVisibleRect
        }
        
        self.cachedCanvasSize = canvasSize
        
        return self.cachedVisibleRect
    }
    
    
    func guiXCoordinate(from x: Double, forCanvasSize canvasSize: Size? = nil) -> Double {
        if let canvasSize = canvasSize, self._cachedCanvasSize != canvasSize {
            self.cachedCanvasSize = canvasSize
        }
        
        return ((x - self.cachedVisibleRect.minX) / self.cachedVisibleRect.size.width) * self._cachedCanvasSize.width
    }
    
    func guiYCoordinate(from y: Double, forCanvasSize canvasSize: Size? = nil) -> Double {
        if let canvasSize = canvasSize, self._cachedCanvasSize != canvasSize {
            self.cachedCanvasSize = canvasSize
        }
        
        return (1 - ((y - self.cachedVisibleRect.minY) / self.cachedVisibleRect.size.height)) * self._cachedCanvasSize.height
    }
    
    func canvasXCoordinate(from x: Double, forCanvasSize canvasSize: Size? = nil) -> Double? {
        if let canvasSize = canvasSize, self._cachedCanvasSize != canvasSize {
            self.cachedCanvasSize = canvasSize
        }
        
        return self.cachedVisibleRect.relativeXCoordinate(from: x) ?* self._cachedCanvasSize.width
    }
    
    func canvasYCoordinate(from y: Double, forCanvasSize canvasSize: Size? = nil) -> Double? {
        if let canvasSize = canvasSize, self._cachedCanvasSize != canvasSize {
            self.cachedCanvasSize = canvasSize
        }
        
        return (1 ?- self.cachedVisibleRect.relativeYCoordinate(from: y)) ?* self._cachedCanvasSize.height
    }
    
    func canvasPoint(from point: Point, forCanvasSize canvasSize: Size? = nil) -> Point? {
        if let canvasSize = canvasSize, self._cachedCanvasSize != canvasSize {
            self.cachedCanvasSize = canvasSize
        }
        
        guard let relative = self.cachedVisibleRect.relativeCoordinates(from: point) else { return nil }
        
        return .init(x: relative.x * self._cachedCanvasSize.width, y: (1 - relative.y) * self._cachedCanvasSize.height)
    }
    
    func canvasCoordinates(from point: Point, forCanvasSize canvasSize: Size? = nil) -> (x: Double?, y: Double?) {
        if let canvasSize = canvasSize, self._cachedCanvasSize != canvasSize {
            self.cachedCanvasSize = canvasSize
        }
        
        return (self.canvasXCoordinate(from: point.x), self.canvasYCoordinate(from: point.y))
    }
    
    
    func xCoordinate(fromCanvasX canvasX: Double, forCanvasSize canvasSize: Size? = nil) -> Double {
        if let canvasSize = canvasSize, self._cachedCanvasSize != canvasSize {
            self.cachedCanvasSize = canvasSize
        }
        
        return self.cachedVisibleRect.absoluteXCoordinate(from: canvasX / self._cachedCanvasSize.width)
    }
    
    func yCoordinate(fromCanvasY canvasY: Double, forCanvasSize canvasSize: Size? = nil) -> Double {
        if let canvasSize = canvasSize, self._cachedCanvasSize != canvasSize {
            self.cachedCanvasSize = canvasSize
        }
        
        return self.cachedVisibleRect.absoluteYCoordinate(from: 1 - (canvasY / self._cachedCanvasSize.height))
    }
    
    func point(fromCanvasPoint canvasPoint: Point, forCanvasSize canvasSize: Size? = nil) -> Point {
        if let canvasSize = canvasSize, self._cachedCanvasSize != canvasSize {
            self.cachedCanvasSize = canvasSize
        }
        
        return .init(x: self.cachedVisibleRect.absoluteXCoordinate(from: canvasPoint.x / self._cachedCanvasSize.width),
                     y: self.cachedVisibleRect.absoluteYCoordinate(from: 1 - (canvasPoint.y / self._cachedCanvasSize.height)))
    }
    
    
    
    func gridLineXCoordinates(forCanvasSize canvasSize: Size? = nil) -> some Sequence<Int> {
        if let canvasSize = canvasSize, self._cachedCanvasSize != canvasSize {
            self.cachedCanvasSize = canvasSize
        }
        
        let startX = Self.gridLineStart(forMin: self.cachedVisibleRect.minX, resolution: self.gridResolution.x)
        
        return stride(from: startX, through: Int(self.cachedVisibleRect.maxX), by: self.gridResolution.x)
    }
    
    func gridLineYCoordinates(forCanvasSize canvasSize: Size? = nil) -> some Sequence<Int> {
        if let canvasSize = canvasSize, self._cachedCanvasSize != canvasSize {
            self.cachedCanvasSize = canvasSize
        }
        
        let startY = Self.gridLineStart(forMin: self.cachedVisibleRect.minY, resolution: self.gridResolution.y)
        
        return stride(from: startY, through: Int(self.cachedVisibleRect.maxY), by: self.gridResolution.y)
    }
    
    
    
    private func recomputeVisibleRect() {
        let ratio = self._cachedCanvasSize.width / self._cachedCanvasSize.height
        
        let unzoomedXOffset = 3.0 * self.xRangeMultiplier
        let unzoomedYOffset = unzoomedXOffset / ratio
        
        let xOffset = unzoomedXOffset * self.xZoomLevel
        let yOffset = unzoomedYOffset * self.yZoomLevel
        
        self.cachedVisibleRect = .init(x: self.centerPoint.x - xOffset, y: self.centerPoint.y - yOffset, width: xOffset * 2.0, height: yOffset * 2.0)
    }
    
    
    private static func gridLineStart(forMin min: Double, resolution: Int) -> Int {
        var startX = Int(min.rounded(.up))
        while startX % resolution != 0 {
            startX += 1
        }
        
        return startX
    }
}
