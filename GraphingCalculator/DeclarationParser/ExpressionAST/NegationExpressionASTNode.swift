//
//  NegationExpressionASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

/**
 * An AST node representing a unary operator and its operand.
 */
struct NegationExpressionASTNode: ExpressionASTNode {
    let token: LexerToken
    let subExpression: any ExpressionASTNode
    
    init(withToken token: LexerToken, subExpression: any ExpressionASTNode) {
        guard case .source(.operator(.subtractionOrNegationOperator), _, _) = token else {
            fatalError("Wrong token for negation expression.")
        }
        
        self.token = token
        self.subExpression = subExpression
    }
    
    private init(constructedWithSubExpression subExpression: any ExpressionASTNode) {
        self.token = .constructed
        self.subExpression = subExpression
    }
    
    static func constructed(withSubExpression subExpression: any ExpressionASTNode) -> Self {
        .init(constructedWithSubExpression: subExpression)
    }
    
    
    func getValue(inContext context: ExpressionContext) throws -> Double {
        try -self.subExpression.getValue(inContext: context)
    }
    
    func checkVariableAccess(withContext context: ExpressionContext) throws {
        try self.subExpression.checkVariableAccess(withContext: context)
    }
    
    func getVariablePowers(withContext context: ExpressionContext) throws -> [Substring: Int]? {
        try self.subExpression.getVariablePowers(withContext: context)
    }
    
    
    func getSimplifiedExpression(inContext context: SimplificationContext) throws -> any ExpressionASTNode {
        let simplifiedExpression = try self.subExpression.getSimplifiedExpression(inContext: context)
        
        switch simplifiedExpression {
        case let binaryExpression as any BinaryOperatorExpressionASTNode:
            return try binaryExpression.getNegatedExpression(inContext: context)
        case let numberExpression as NumberExpressionASTNode:
            switch numberExpression.value {
            case let .integer(integerValue):
                return NumberExpressionASTNode.constructed(withValue: -integerValue)
            case let .double(doubleValue):
                return NumberExpressionASTNode.constructed(withValue: -doubleValue)
            }
        case let unaryExpression as NegationExpressionASTNode:
            return unaryExpression.subExpression
        default:
            return Self(constructedWithSubExpression: simplifiedExpression)
        }
    }
    
    
    var description: String {
        if let binaryExpression = self.subExpression as? any BinaryOperatorExpressionASTNode {
            return "-(\(binaryExpression))"
        } else {
            return "-\(subExpression)"
        }
    }
}
