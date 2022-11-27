//
//  FunctionDeclarationASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

struct FunctionDeclarationASTNode: DeclarationASTNode {
    let token: LexerToken
    let functionName, argumentName: Substring
    let expression: any ExpressionASTNode
    
    init(withToken token: LexerToken, functionName: Substring, argumentName: Substring, expression: any ExpressionASTNode) {
        self.token = token
        self.functionName = functionName
        self.argumentName = argumentName
        self.expression = expression
    }
    
    
    func getSimplifiedDeclaration(inContext context: SimplificationContext) throws -> FunctionDeclarationASTNode {
        let simplifiedExpression = try self.expression.getSimplifiedExpression(inContext: context)
        
        return FunctionDeclarationASTNode(withToken: self.token, functionName: self.functionName, argumentName: self.argumentName, expression: simplifiedExpression)
    }
    
    
    func getSimplifiedExpression(inContext context: SimplificationContext, withAppliedSubstitution substitution: any ExpressionASTNode) throws -> any ExpressionASTNode {
        let functionContext = SimplificationContext(copying: context)
        functionContext.setSubstitution(forName: self.argumentName, to: substitution)
        
        return try self.expression.getSimplifiedExpression(inContext: functionContext)
    }
    
    
    var description: String {
        "\(self.functionName)(\(self.argumentName)) = \(self.expression)"
    }
}
