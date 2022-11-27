//
//  NumberExpressionASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

/**
 * An AST node representing a number literal.
 */
struct NumberExpressionASTNode: ExpressionASTNode {
    enum Value: CustomStringConvertible {
        case integer(Int)
        case double(Double)
        
        var doubleValue: Double {
            switch self {
            case let .integer(value):
                return Double(value)
            case let .double(value):
                return value
            }
        }
        
        var description: String {
            switch self {
            case let .integer(value):
                return "\(value)"
            case let .double(value):
                return "\(value)"
            }
        }
    }
    
    let token: LexerToken
    let value: Value
    
    init(withToken token: LexerToken, value: Int) {
        self.token = token
        self.value = .integer(value)
    }
    
    init(withToken token: LexerToken, value: Double) {
        self.token = token
        self.value = value.isInteger ? .integer(Int(value)) : .double(value)
    }
    
    static func constructed(withValue value: Int) -> Self {
        .init(withToken: .constructed, value: value)
    }
    
    static func constructed(withValue value: Double) -> Self {
        .init(withToken: .constructed, value: value)
    }
    
    
    func getValue(inContext context: ExpressionContext) throws -> Double {
        self.value.doubleValue
    }
    
    func checkVariableAccess(withContext context: ExpressionContext) throws {}
    
    func getVariablePowers(withContext context: ExpressionContext) -> [Substring: Int]? {
        [:]
    }
    
    
    func getSimplifiedExpression(inContext context: SimplificationContext) throws -> any ExpressionASTNode {
        self
    }
    
    
    var description: String {
        "\(self.value)"
    }
}
