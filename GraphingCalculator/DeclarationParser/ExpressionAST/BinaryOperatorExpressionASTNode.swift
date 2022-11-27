//
//  BinaryOperatorExpressionASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

/**
 * An AST node representing a binary operator with its two operands.
 */
protocol BinaryOperatorExpressionASTNode: ExpressionASTNode {
    static var precedence: BinaryOperatorPrecedence { get }
    
    func getNegatedExpression(inContext context: SimplificationContext) throws -> any ExpressionASTNode
}

extension BinaryOperatorExpressionASTNode {
    func hasHigherOrEqualPrecedence<Other>(comparedTo other: Other) -> Bool where Other: BinaryOperatorExpressionASTNode {
        switch (Self.precedence, Other.precedence) {
        case (.multiplication, .exponentiation): return false
        case (.exponentiation, _),
             (.multiplication, _),
             (.addition, .addition): return true
        default: return false
        }
    }
}
