//
//  LexerToken.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

enum LexerToken {
    enum ErrorType {
        case invalidCharacter
        case noDigitAfterDecimalPoint
        case noDigitAfterE
    }
    
    enum OperatorType {
        case additionOrIdentityOperator
        case subtractionOrNegationOperator
        case multiplicationOperator
        case divisionOperator
        case exponentiationOperator
    }
    
    enum `Type`: Equatable {
        case `operator`(type: OperatorType)
        
        case equalsSign
        
        case leftParenthesis
        case rightParenthesis
        
        case identifier
        case numberLiteral
    }
    
    case source(type: Type, startIndex: String.Index, endIndex: String.Index)
    case error(type: ErrorType, index: String.Index)
    case endOfInput
    case constructed
}
