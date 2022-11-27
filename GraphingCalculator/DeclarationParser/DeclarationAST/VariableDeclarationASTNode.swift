//
//  VariableDeclarationASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

struct VariableDeclarationASTNode: DeclarationASTNode {
    let token: LexerToken
    let name: Substring
    let expression: any ExpressionASTNode
    
    init(withToken token: LexerToken, name: Substring, expression: any ExpressionASTNode) {
        self.token = token
        self.name = name
        self.expression = expression
    }
    
    
    func getSimplifiedDeclaration(inContext context: SimplificationContext) throws -> VariableDeclarationASTNode {
        let simplifiedExpression = try self.expression.getSimplifiedExpression(inContext: context)
        
        return VariableDeclarationASTNode(withToken: self.token, name: self.name, expression: simplifiedExpression)
    }
    
    
    var description: String {
        return "\(name) = \(expression)"
    }
}
