//
//  VariableExpressionASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

/**
 * An AST node representing a variable.
 */
struct VariableExpressionASTNode: ExpressionASTNode {
    let token: LexerToken
    let name: Substring
    
    init(withToken token: LexerToken, name: Substring) {
        self.token = token
        self.name = name
    }
    
    private init(constructedWithName name: Substring) {
        self.token = .constructed
        self.name = name
    }
    
    static func constructed(withName name: Substring) -> Self {
        .init(constructedWithName: name)
    }
    
    
    func getValue(inContext context: ExpressionContext) throws -> Double {
        try context.getValueOfVariable(withName: self.name)
    }
    
    func checkVariableAccess(withContext context: ExpressionContext) throws {
        _ = try context.getValueOfVariable(withName: self.name)
    }
    
    func getVariablePowers(withContext context: ExpressionContext) -> [Substring: Int]? {
        context.getVariable(withName: self.name) == nil ? [self.name: 1] : [:]
    }
    
    
    func getSimplifiedExpression(inContext context: SimplificationContext) throws -> any ExpressionASTNode {
        if let variable = context.getVariable(withName: self.name) {
            return NumberExpressionASTNode.constructed(withValue: variable.value)
        } else if let substitution = context.getSubstitution(forName: name) {
            return substitution.expression
        } else {
            return self
        }
    }
    
    
    var description: String {
        return String(self.name)
    }
}
