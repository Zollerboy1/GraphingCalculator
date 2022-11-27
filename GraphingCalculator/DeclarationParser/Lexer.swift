//
//  Lexer.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

class Lexer {
    private enum NumberFSMState {
        case begin
        case integer
        case beginDecimal
        case decimal
        case beginExponent
        case beginSignedExponent
        case decimalWithExponent
    }
    
    
    private let sourceString: String
    private var startIndex, currentIndex: String.Index
    
    
    init(sourceString: String) {
        self.sourceString = sourceString
        
        self.startIndex = sourceString.startIndex
        self.currentIndex = sourceString.startIndex
    }
    
    
    func nextToken() -> LexerToken {
        if self.isAtEnd {
            return .endOfInput
        }
    
        while !self.isAtEnd {
            self.startIndex = self.currentIndex
            
            let c = advance()
            
            switch c {
            case "+": return self.makeOperatorToken(withType: .additionOrIdentityOperator)
            case "-": return self.makeOperatorToken(withType: .subtractionOrNegationOperator)
            case "*": return self.makeOperatorToken(withType: .multiplicationOperator)
            case "/": return self.makeOperatorToken(withType: .divisionOperator)
            case "^": return self.makeOperatorToken(withType: .exponentiationOperator)
            case "=": return self.makeToken(withType: .equalsSign)
            case "(": return self.makeToken(withType: .leftParenthesis)
            case ")": return self.makeToken(withType: .rightParenthesis)
            default:
                if c.isIdentifierHead {
                    return self.matchIdentifier()
                }
                
                if c.isDigit {
                    return self.matchNumberLiteral()
                }

                if (c.isWhitespace) {
                    while !self.isAtEnd && self.peek.isWhitespace {
                        self.advance()
                    }
                    
                    break
                }
                
                return self.errorToken(withType: .invalidCharacter)
            }
        }
        
        return .endOfInput
    }
    
    
    // A little finite state machine for lexing numbers
    private func matchNumberLiteral() -> LexerToken {
        var currentIndex = self.startIndex
        var currentState = NumberFSMState.begin
    
        var character: Character { self.sourceString[currentIndex] }
        
        
        loop: while (currentIndex != self.sourceString.endIndex) {
            switch currentState {
            case .begin:
                assert(character.isDigit)
                currentState = .integer
            case .integer:
                if character.isDigit { break }
                
                if character == "." {
                    currentState = .beginDecimal
                    break
                }
                
                if character.lowercased() == "e" {
                    currentState = .beginExponent
                    break
                }
                
                break loop
            case .beginDecimal:
                if character.isDigit {
                    currentState = .decimal
                    break
                }
                
                break loop
            case .decimal:
                if character.isDigit { break }
                
                if character.lowercased() == "e" {
                    currentState = .beginExponent
                    break
                }

                break loop
            case .beginExponent:
                if character == "+" || character == "-" {
                    currentState = .beginSignedExponent
                    break
                }
                
                fallthrough
            case .beginSignedExponent:
                if character.isDigit {
                    currentState = .decimalWithExponent
                    break
                }
                
                break loop
            case .decimalWithExponent:
                if character.isDigit { break }
                
                break loop
            }
            
            self.sourceString.formIndex(after: &currentIndex)
        }
        
        switch currentState {
        case .beginDecimal:
            return self.errorToken(withType: .noDigitAfterDecimalPoint, index: currentIndex)
        case .beginExponent,
             .beginSignedExponent:
            return self.errorToken(withType: .noDigitAfterE, index: currentIndex)
        default:
            self.currentIndex = currentIndex
            
            return self.makeToken(withType: .numberLiteral)
        }
    }
    
    private func matchIdentifier() -> LexerToken {
        while !self.isAtEnd && peek.isIdentifierCharacter {
            self.advance()
        }
        
        return makeToken(withType: .identifier)
    }
    
    
    private func errorToken(withType errorType: LexerToken.ErrorType, index: String.Index? = nil) -> LexerToken {
        .error(type: errorType, index: index ?? self.currentIndex)
    }
    
    private func makeOperatorToken(withType type: LexerToken.OperatorType) -> LexerToken {
        .source(type: .operator(type: type), startIndex: self.startIndex, endIndex: self.currentIndex)
    }
    
    private func makeToken(withType type: LexerToken.`Type`) -> LexerToken {
        .source(type: type, startIndex: self.startIndex, endIndex: self.currentIndex)
    }
    
    
    @discardableResult
    private func advance() -> Character {
        let c = self.peek
        self.sourceString.formIndex(after: &self.currentIndex)
        return c
    }
    
    private var isAtEnd: Bool { self.currentIndex == self.sourceString.endIndex }
    
    private var peek: Character { self.sourceString[currentIndex] }
}
