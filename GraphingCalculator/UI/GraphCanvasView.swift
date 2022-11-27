//
//  GraphCanvasView.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 13.01.22.
//

import SwiftUI

struct GraphCanvasView: View {
    private static let stepThreshold = 2.0
    
    
    @Binding var xAxisIsHovered: Bool
    @Binding var yAxisIsHovered: Bool
    
    @Binding var sidebarWidth: Double
    
    @EnvironmentObject var state: GraphState
    
    @State var evaluationErrorMessages = [String]()
    
    
    init(xAxisIsHovered: Binding<Bool>, yAxisIsHovered: Binding<Bool>, sidebarWidth: Binding<Double>) {
        self._xAxisIsHovered = xAxisIsHovered
        self._yAxisIsHovered = yAxisIsHovered
        self._sidebarWidth = sidebarWidth
    }
    
    
    var body: some View {
        Canvas { context, size in
            let size = Size(size)
            
            let visibleRect = self.state.visibleRect(forCanvasSize: size)
            
            let (originX, originY) = self.state.canvasCoordinates(from: .zero)
            
            
            let gridPath = Path { path in
                for x in self.state.gridLineXCoordinates() {
                    if x != 0 {
                        guard let canvasX = self.state.canvasXCoordinate(from: Double(x)) else { continue }
                        
                        path.move(to: .init(x: canvasX, y: 0))
                        path.addLine(to: .init(x: canvasX, y: size.height))
                        
                        
                        let coordinatePoint: CGPoint
                        let anchor: UnitPoint
                        if let originY {
                            coordinatePoint = .init(x: canvasX - 4, y: originY + 3)
                            anchor = .topTrailing
                        } else if self.state.centerPoint.y > 0 {
                            coordinatePoint = .init(x: canvasX - 4, y: size.height - 3)
                            anchor = .bottomTrailing
                        } else {
                            coordinatePoint = .init(x: canvasX - 4, y: 3)
                            anchor = .topTrailing
                        }
                        
                        context.draw(Text("\(x)").foregroundColor(.gridline), at: coordinatePoint, anchor: anchor)
                    }
                }
                
                for y in self.state.gridLineYCoordinates() {
                    if y != 0 {
                        guard let canvasY = self.state.canvasYCoordinate(from: Double(y)) else { continue }
                        
                        path.move(to: .init(x: 0, y: canvasY))
                        path.addLine(to: .init(x: size.width, y: canvasY))
                        
                        
                        let coordinatePoint: CGPoint
                        let anchor: UnitPoint
                        if let originX {
                            if originX <= self.sidebarWidth {
                                coordinatePoint = .init(x: self.sidebarWidth + 4, y: canvasY + 3)
                                anchor = .topLeading
                            } else {
                                coordinatePoint = .init(x: originX - 4, y: canvasY + 3)
                                anchor = .topTrailing
                            }
                        } else if self.state.centerPoint.x > 0 {
                            coordinatePoint = .init(x: self.sidebarWidth + 4, y: canvasY + 3)
                            anchor = .topLeading
                        } else {
                            coordinatePoint = .init(x: size.width - 4, y: canvasY + 3)
                            anchor = .topTrailing
                        }
                        
                        context.draw(Text("\(y)").foregroundColor(.gridline), at: coordinatePoint, anchor: anchor)
                    }
                }
            }
            
            context.stroke(gridPath, with: .color(.gridline))
            
            
            let axisPath = Path { path in
                if let originX = originX {
                    path.move(to: .init(x: originX, y: 0))
                    path.addLine(to: .init(x: originX, y: size.height))
                }
                
                if let originY = originY {
                    path.move(to: .init(x: 0, y: originY))
                    path.addLine(to: .init(x: size.width, y: originY))
                }
            }
            
            context.stroke(axisPath, with: .color(.white))
            
            if let originX = originX, let originY = originY {
                context.draw(Text("0").foregroundColor(.white), at: .init(x: originX - 4, y: originY + 3), anchor: .topTrailing)
            }
            
            
            let axisHoverPath = Path { path in
                if let originX = originX, self.yAxisIsHovered {
                    path.move(to: .init(x: originX, y: 0))
                    path.addLine(to: .init(x: originX, y: size.height))
                }
                
                if let originY = originY, self.xAxisIsHovered {
                    path.move(to: .init(x: 0, y: originY))
                    path.addLine(to: .init(x: size.width, y: originY))
                }
            }
            
            context.stroke(axisHoverPath, with: .color(white: 1.0, opacity: 0.25), lineWidth: 5.0)
            
            
            let expressionContext = ExpressionContext()
            var evaluationErrorMessages = [String]()
            
            for (declaration, color) in self.state.declarations.compactMap({ $0 }) {
                var continueLoop = false
                switch declaration.storage {
                case let .function(functionDeclaration):
                    let color = color!.0
                    
                    let name = functionDeclaration.functionName
                    
                    guard name != "x" && name != "y" else {
                        evaluationErrorMessages.append("Cannot declare function with name '\(name)'.")
                        continue
                    }
                    
                    guard expressionContext.getVariable(withName: name) == nil && expressionContext.getFunction(withName: name) == nil else {
                        evaluationErrorMessages.append("Declaration with name '\(name)' already exists.")
                        continue
                    }
                    
                    let argumentName = functionDeclaration.argumentName
                    
                    if argumentName == "x" || argumentName == "y" {
                        var possibleNamePositions = (Double.nan, Double.nan, Double.nan, Double.nan)
                        var subtractFromNamePosition = (false, false, false, false)
                                            
                        let functionContext = ExpressionContext(copying: expressionContext)
                        
                        let functionPath = Path { path in
                            var alreadyHadZeroDivision = false
                            var previousX = Double.nan
                            var previousY = Double.nan
                            
                            if argumentName == "x" {
                                for canvasX in stride(from: 0, through: size.width, by: 0.1) {
                                    let x = self.state.xCoordinate(fromCanvasX: canvasX)
                                    
                                    functionContext.setVariable(withName: "x", to: x)
                                    
                                    do {
                                        let y = try functionDeclaration.expression.getValue(inContext: functionContext)
                                        
                                        let guiY = self.state.guiYCoordinate(from: y)
                                        
                                        if y.isFinite {
                                            if previousX.isFinite && previousY.isFinite && (y - previousY).magnitude <= Self.stepThreshold {
                                                path.addLine(to: .init(x: canvasX, y: guiY))
                                                
                                                if canvasX > self.sidebarWidth {
                                                    if (previousY < visibleRect.minY && y > visibleRect.minY) || (previousY > visibleRect.minY && y < visibleRect.minY) {
                                                        do {
                                                            functionContext.setVariable(withName: "x", to: x + 0.01 * self.state.xZoomLevel)
                                                            let nextY = try functionDeclaration.expression.getValue(inContext: functionContext)
                                                            
                                                            possibleNamePositions.1 = x
                                                            
                                                            subtractFromNamePosition.1 = nextY > y
                                                        } catch {}
                                                    } else if (previousY < visibleRect.maxY && y > visibleRect.maxY) || (previousY > visibleRect.maxY && y < visibleRect.maxY) {
                                                        do {
                                                            functionContext.setVariable(withName: "x", to: x + 0.01 * self.state.xZoomLevel)
                                                            let nextY = try functionDeclaration.expression.getValue(inContext: functionContext)
                                                            
                                                            possibleNamePositions.3 = x
                                                            
                                                            subtractFromNamePosition.3 = nextY < y
                                                        } catch {}
                                                    }
                                                }
                                            } else {
                                                path.move(to: .init(x: canvasX, y: guiY))
                                            }
                                        }
                                        
                                        previousX = x
                                        previousY = y
                                        
                                        if (canvasX - self.sidebarWidth).magnitude <= 0.05 && y > visibleRect.minY && y < visibleRect.maxY {
                                            do {
                                                functionContext.setVariable(withName: "x", to: x + 0.01 * self.state.xZoomLevel)
                                                let nextY = try functionDeclaration.expression.getValue(inContext: functionContext)
                                                
                                                possibleNamePositions.0 = y
            
                                                subtractFromNamePosition.0 = nextY < y
                                            } catch {}
                                        } else if (canvasX - size.width).magnitude <= 0.05 && y > visibleRect.minY && y < visibleRect.maxY {
                                            do {
                                                functionContext.setVariable(withName: "x", to: x + 0.01 * self.state.xZoomLevel)
                                                let nextY = try functionDeclaration.expression.getValue(inContext: functionContext)
                                                
                                                possibleNamePositions.2 = y
            
                                                subtractFromNamePosition.2 = nextY > y
                                            } catch {}
                                        }
                                    } catch is DivisionByZeroError {
                                        if alreadyHadZeroDivision {
                                            evaluationErrorMessages.append("Division by zero occurred too frequently while evaluating function.")
                                            continueLoop = true
                                            return
                                        } else {
                                            alreadyHadZeroDivision = true
                            
                                            previousX = .nan
                                            previousY = .nan
                                        }
                                    } catch let error as EvaluationError {
                                        evaluationErrorMessages.append(error.message)
                                        continueLoop = true
                                        return
                                    } catch {
                                        evaluationErrorMessages.append("Unknown error: \(error.localizedDescription)")
                                        continueLoop = true
                                        return
                                    }
                                }
                            } else {
                                let sidebarX = self.state.xCoordinate(fromCanvasX: self.sidebarWidth)
                                
                                for canvasY in stride(from: 0, through: size.height, by: 0.1) {
                                    let y = self.state.yCoordinate(fromCanvasY: canvasY)
                                    
                                    functionContext.setVariable(withName: "y", to: y)
                                    
                                    do {
                                        let x = try functionDeclaration.expression.getValue(inContext: functionContext)
                                        
                                        let guiX = self.state.guiXCoordinate(from: x)
                                        
                                        if x.isFinite {
                                            if previousX.isFinite && previousY.isFinite && (x - previousX).magnitude <= Self.stepThreshold {
                                                path.addLine(to: .init(x: guiX, y: canvasY))
                                                
                                                if (previousX < sidebarX && x > sidebarX) || (previousX > sidebarX && x < sidebarX) {
                                                    do {
                                                        functionContext.setVariable(withName: "y", to: y + 0.01 * self.state.yZoomLevel)
                                                        let nextX = try functionDeclaration.expression.getValue(inContext: functionContext)
                                                        
                                                        possibleNamePositions.0 = y
                    
                                                        subtractFromNamePosition.0 = nextX < x
                                                    } catch {}
                                                } else if (previousX < visibleRect.maxX && x > visibleRect.maxX) || (previousX > visibleRect.maxX && x < visibleRect.maxX) {
                                                    do {
                                                        functionContext.setVariable(withName: "y", to: y + 0.01 * self.state.yZoomLevel)
                                                        let nextX = try functionDeclaration.expression.getValue(inContext: functionContext)
                                                        
                                                        possibleNamePositions.2 = y
                    
                                                        subtractFromNamePosition.2 = nextX > x
                                                    } catch {}
                                                }
                                            } else {
                                                path.move(to: .init(x: guiX, y: canvasY))
                                            }
                                        }
                                        
                                        previousX = x
                                        previousY = y
                                        
                                        if x > sidebarX && x < visibleRect.maxX {
                                            if canvasY == 0 && x > sidebarX && x < visibleRect.maxX {
                                                do {
                                                    functionContext.setVariable(withName: "y", to: y + 0.01 * self.state.yZoomLevel)
                                                    let nextX = try functionDeclaration.expression.getValue(inContext: functionContext)
                                                    
                                                    possibleNamePositions.3 = x
                                                    
                                                    subtractFromNamePosition.3 = nextX < x
                                                } catch {}
                                            } else if (canvasY - size.height).magnitude < 0.05 && x > sidebarX && x < visibleRect.maxX {
                                                do {
                                                    functionContext.setVariable(withName: "y", to: y + 0.01 * self.state.yZoomLevel)
                                                    let nextX = try functionDeclaration.expression.getValue(inContext: functionContext)
                                                    
                                                    possibleNamePositions.1 = x
                                                    
                                                    subtractFromNamePosition.1 = nextX > x
                                                } catch {}
                                            }
                                        }
                                    } catch is DivisionByZeroError {
                                        if alreadyHadZeroDivision {
                                            evaluationErrorMessages.append("Division by zero occurred to frequently while evaluating function.")
                                            continueLoop = true
                                            return
                                        } else {
                                            alreadyHadZeroDivision = true
                            
                                            previousX = .nan
                                            previousY = .nan
                                        }
                                    } catch let error as EvaluationError {
                                        evaluationErrorMessages.append(error.message)
                                        continueLoop = true
                                        return
                                    } catch {
                                        evaluationErrorMessages.append("Unknown error: \(error.localizedDescription)")
                                        continueLoop = true
                                        return
                                    }
                                }
                            }
                        }
                        
                        if continueLoop {
                            continue
                        }
                        
                        context.stroke(functionPath, with: .color(color))
                        
                        
                        let functionText = Text(String("\(name)(\(argumentName))"))
                        
                        let point: CGPoint?
                        let anchor: UnitPoint?
                        if possibleNamePositions.0.isFinite {
                            point = .init(x: self.sidebarWidth + 3, y: self.state.guiYCoordinate(from: possibleNamePositions.0) + (subtractFromNamePosition.0 ? -3 : 3))
                            anchor = subtractFromNamePosition.0 ? .bottomLeading : .topLeading
                        } else if possibleNamePositions.1.isFinite {
                            point = .init(x: self.state.guiXCoordinate(from: possibleNamePositions.1) + (subtractFromNamePosition.1 ? -3 : 3), y: size.height - 5)
                            anchor = subtractFromNamePosition.1 ? .bottomTrailing : .bottomLeading
                        } else if possibleNamePositions.2.isFinite {
                            point = .init(x: size.width - 3, y: self.state.guiYCoordinate(from: possibleNamePositions.2) + (subtractFromNamePosition.2 ? -3 : 3))
                            anchor = subtractFromNamePosition.2 ? .bottomTrailing : .topTrailing
                        } else if possibleNamePositions.3.isFinite {
                            point = .init(x: self.state.guiXCoordinate(from: possibleNamePositions.3) + (subtractFromNamePosition.3 ? -3 : 3), y: 5)
                            anchor = subtractFromNamePosition.3 ? .topTrailing : .topLeading
                        } else {
                            point = nil
                            anchor = nil
                        }
                        
                        if let point, let anchor {
                            context.draw(functionText, at: point, anchor: anchor)
                        }
                    }
                    
                    expressionContext.setFunction(withName: name, to: functionDeclaration)
                case let .variable(variableDeclaration):
                    let name = variableDeclaration.name
                    
                    guard name != "x" && name != "y" else {
                        evaluationErrorMessages.append("Cannot declare variable with name '\(name)'.")
                        continue
                    }
                    
                    guard expressionContext.getVariable(withName: name) == nil && expressionContext.getFunction(withName: name) == nil else {
                        evaluationErrorMessages.append("Declaration with name '\(name)' already exists.")
                        continue
                    }
                    
                    do {
                        let value = try variableDeclaration.expression.getValue(inContext: expressionContext)
                        
                        expressionContext.setVariable(withName: name, to: value)
                    } catch let error as EvaluationError {
                        evaluationErrorMessages.append(error.message)
                    } catch {
                        evaluationErrorMessages.append("Unknown error: \(error.localizedDescription)")
                    }
                default:
                    break
                }
            }
            
            
            
            if let originX = originX {
                context.draw(Text("y"), at: .init(x: originX - 4, y: 3), anchor: .topTrailing)
            }
            
            if let originY = originY {
                context.draw(Text("x"), at: .init(x: size.width - 4, y: originY + 3), anchor: .topTrailing)
            }
        }
        .background(Color.canvasBackground)
    }
}


struct GraphCanvasView_Previews: PreviewProvider {
    static var previews: some View {
        GraphCanvasView(xAxisIsHovered: .constant(false), yAxisIsHovered: .constant(false), sidebarWidth: .constant(200))
    }
}
