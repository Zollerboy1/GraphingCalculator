//
//  UnknownNameError.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 27.11.22.
//

enum UnknownNameError: Error {
    case variable(name: Substring)
    case function(name: Substring)
}
