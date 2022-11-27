//
//  MathFontFormatter.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

import Foundation


struct MathFontFormatter: TextFieldFormatter {
    func displayString(for value: String) -> String {
        .init(value.map(\.convertedToMathFont))
    }
    
    func editingString(for value: String) -> String {
        .init(value.map(\.convertedToMathFont))
    }
    
    func value(from string: String) -> String {
        .init(string.map(\.convertedToNormalFont))
    }
}
