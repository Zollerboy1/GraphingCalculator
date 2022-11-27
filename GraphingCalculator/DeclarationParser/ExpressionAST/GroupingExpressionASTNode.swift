//
//  GroupingExpressionASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

/**
 * An AST node representing a grouped subexpression.
 */
struct GroupingExpressionASTNode: ExpressionASTNode {
    let token: LexerToken
    let subExpression: any ExpressionASTNode
    
    init(withToken token: LexerToken, subExpression: any ExpressionASTNode) {
        self.token = token
        self.subExpression = subExpression
    }
    
    
    func getValue(inContext context: ExpressionContext) throws -> Double {
        try self.subExpression.getValue(inContext: context)
    }
    
    func checkVariableAccess(withContext context: ExpressionContext) throws {
        try self.subExpression.checkVariableAccess(withContext: context)
    }
    
    func getVariablePowers(withContext context: ExpressionContext) throws -> [Substring: Int]? {
        try self.subExpression.getVariablePowers(withContext: context)
    }
    
    
    func getSimplifiedExpression(inContext context: SimplificationContext) throws -> any ExpressionASTNode {
        try self.subExpression.getSimplifiedExpression(inContext: context)
    }
    
    
    var description: String {
        "(\(self.subExpression))"
    }
}
