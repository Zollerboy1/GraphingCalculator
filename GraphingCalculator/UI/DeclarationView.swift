//
//  DeclarationView.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

import SFSymbols
import SwiftUI


struct DeclarationView: View {
    @EnvironmentObject var state: GraphState
    
    let index: Int
    
    @Binding var string: String
    
    @State private var shouldShowPopover = false
    
    
    private var colorBinding: Binding<Color>? {
        if case .function = self.declaration?.0.storage {
            return .init {
                self.declaration!.1!.0
            } set: { newColor in
                self.state.declarations[self.index]!.1 = (newColor, true)
            }
        } else {
            return nil
        }
    }
    
    
    private var declaration: (Declaration, (Color, Bool)?)? {
        self.index < self.state.declarations.count ? self.state.declarations[self.index] : nil
    }
    
    private var errorMessage: String? {
        switch self.declaration?.0.storage {
        case let .error(message):
            return message
        default:
            return nil
        }
    }
    
    private var buttonSymbol: SFSymbol {
        switch self.declaration?.0.storage {
        case .none:
            return self.string.isEmpty ? .circleDashed : .exclamationmarkCircle
        case .function:
            return .fCursiveCircleFill
        case .variable:
            return .vCircleFill
        case .error:
            return .exclamationmarkCircle
        }
    }
    
    private var buttonColor: Color {
        switch self.declaration?.0.storage {
        case .none:
            return self.string.isEmpty ? .white : .red
        case .function:
            return self.declaration!.1!.0
        case .variable:
            return .white
        case .error:
            return .red
        }
    }
    
    private var textColor: Color {
        switch self.declaration?.0.storage {
        case .error:
            return .red
        default:
            return .white
        }
    }
    
    private var buttonIsDisabled: Bool {
        self.declaration == nil
    }
    
    
    var body: some View {
        HStack {
            Button {
                switch self.declaration?.0.storage {
                case .function, .error:
                    self.shouldShowPopover = true
                default:
                    break
                }
            } label: {
                Image(symbol: self.buttonSymbol)
            }
            .disabled(self.buttonIsDisabled)
            .buttonStyle(.plain)
            .font(.system(size: 17))
            .foregroundColor(self.buttonColor)
            .if(self.colorBinding != nil) { view in
                view.popover(isPresented: self.$shouldShowPopover, attachmentAnchor: .point(.trailing), arrowEdge: .trailing) {
                    ColorPicker(color: self.colorBinding!)
                        .padding(8)
                }
            }
            .if(self.errorMessage != nil) { view in
                view.popover(isPresented: self.$shouldShowPopover, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
                    Text(self.errorMessage!)
                        .foregroundColor(.red)
                        .padding(8)
                }
            }
            Divider()
            FormattedTextField(value: self.$string, formatter: MathFontFormatter(), placeholder: "𝑓(𝑥) = 𝑥", font: .init(name: "LatinModernMath-Regular", size: 15), textColor: self.textColor)
                .formattedTextFieldStyle(.plain)
        }
    }
}
