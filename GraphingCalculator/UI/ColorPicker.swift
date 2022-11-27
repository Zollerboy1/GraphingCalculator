//
//  ColorPicker.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 05.07.22.
//

import SwiftUI

struct ColorPicker: View {
    static private let builtinColors: [Color] = [
        .red,
        .pink,
        .purple,
        .indigo,
        .darkBlue,
        .blue,
        .cyan,
        .mint,
        .lime,
        .green,
        .yellow,
        .orange
    ]
    
    static private let colorModifications: [(Color) -> Color] = {
        func shaded(by factor: Double) -> (Color) -> Color {
            { $0.shaded(by: factor) }
        }
        
        func tinted(by factor: Double) -> (Color) -> Color {
            { $0.tinted(by: factor) }
        }
        
        return [
            tinted(by: 0.8),
            tinted(by: 0.7),
            tinted(by: 0.6),
            tinted(by: 0.4),
            tinted(by: 0.2),
            { $0 },
            shaded(by: 0.2),
            shaded(by: 0.4),
            shaded(by: 0.6),
            shaded(by: 0.7),
            shaded(by: 0.8)
        ]
    }()
    
    
    @Binding var color: Color
    
    var body: some View {
        Grid(horizontalSpacing: 3, verticalSpacing: 3) {
            ForEach(Self.builtinColors, id: \.self) { color in
                GridRow {
                    ForEach(Self.colorModifications.enumerated(), id: \.offset) { _, modification in
                        let color = modification(color)
                        
                        Rectangle()
                            .fill(color.shadow(.inner(radius: color == self.color ? 8 : 0)))
                            .if(color == self.color) { view in
                                view.border(.white)
                            }
                            .onTapGesture {
                                self.color = color
                            }
                    }
                }
            }
        }
        .frame(width: 330, height: 360)
    }
}

struct ColorPicker_Previews: PreviewProvider {
    static var previews: some View {
        ColorPicker(color: .constant(.red))
    }
}
