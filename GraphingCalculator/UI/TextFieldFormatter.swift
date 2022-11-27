//
//  TextFieldFormatter.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//


protocol TextFieldFormatter {
    associatedtype Value
    func displayString(for value: Value) -> String
    func editingString(for value: Value) -> String
    func value(from string: String) -> Value
}
