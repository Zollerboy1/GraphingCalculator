//
//  DivisionExpressionASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 27.11.22.
//

struct DivisionExpressionASTNode: BinaryOperatorExpressionASTNode {
    static let precedence = BinaryOperatorPrecedence.multiplication
    
    let token: LexerToken
    let left, right: any ExpressionASTNode
    
    init(withToken token: LexerToken, left: any ExpressionASTNode, right: any ExpressionASTNode) {
        guard case .source(.operator(.divisionOperator), _, _) = token else {
            fatalError("Wrong token for division expression.")
        }
        
        self.token = token
        self.left = left
        self.right = right
    }
    
    private init(constructedWithLeft left: any ExpressionASTNode, right: any ExpressionASTNode) {
        self.token = .constructed
        self.left = left
        self.right = right
    }
    
    static func constructed(withLeft left: any ExpressionASTNode, right: any ExpressionASTNode) -> Self {
        .init(constructedWithLeft: left, right: right)
    }
    
    
    func getValue(inContext context: ExpressionContext) throws -> Double {
        let leftValue = try self.left.getValue(inContext: context)
        let rightValue = try self.right.getValue(inContext: context)
        
        guard !rightValue.isApproximatelyEqual(to: 0) else {
            throw DivisionByZeroError()
        }
        
        return leftValue / rightValue
    }
    
    func checkVariableAccess(withContext context: ExpressionContext) throws {
        try self.left.checkVariableAccess(withContext: context)
        try self.right.checkVariableAccess(withContext: context)
    }
    
    func getVariablePowers(withContext context: ExpressionContext) throws -> [Substring: Int]? {
        let leftPowers = try self.left.getVariablePowers(withContext: context)
        let rightPowers = try self.right.getVariablePowers(withContext: context)
        
        return (rightPowers?.mapValues(-)).flatMap {
            leftPowers?.merging($0, uniquingKeysWith: +)
        }
    }
    
    
    func getSimplifiedExpression(inContext context: SimplificationContext) throws -> any ExpressionASTNode {
        var simplifiedLeftExpression = try self.left.getSimplifiedExpression(inContext: context)
        var simplifiedRightExpression = try self.right.getSimplifiedExpression(inContext: context)
        
        let leftValue = (simplifiedLeftExpression as? NumberExpressionASTNode)?.value
        let rightValue = (simplifiedRightExpression as? NumberExpressionASTNode)?.value
        
        if let leftValue, let rightValue {
            if case .integer(0) = rightValue {
                throw DivisionByZeroError()
            }
            
            return NumberExpressionASTNode.constructed(withValue: leftValue.doubleValue / rightValue.doubleValue)
        } else if let leftDivisionExpression = simplifiedLeftExpression as? DivisionExpressionASTNode {
            let leftRight = leftDivisionExpression.right
            
            let newRight: any ExpressionASTNode
            if let multiplicationExpression = leftRight as? MultiplicationExpressionASTNode {
                newRight = try multiplicationExpression.withAppendedSubexpression(simplifiedRightExpression)
                                                           .getSimplifiedExpression(inContext: context)
            } else {
                newRight = try MultiplicationExpressionASTNode.constructed(withSubExpressions: [leftRight, simplifiedRightExpression])
                                                                  .getSimplifiedExpression(inContext: context)
            }
            
            return DivisionExpressionASTNode(constructedWithLeft: leftDivisionExpression.left, right: newRight)
        } else if case let .integer(rightValue) = rightValue {
            if rightValue == 0 {
                throw DivisionByZeroError()
            } else if rightValue == 1 {
                return simplifiedLeftExpression
            } else if rightValue == -1 {
                return try NegationExpressionASTNode.constructed(withSubExpression: simplifiedLeftExpression)
                                                    .getSimplifiedExpression(inContext: context)
            } else if rightValue < 0 {
                simplifiedLeftExpression = try NegationExpressionASTNode.constructed(withSubExpression: simplifiedLeftExpression)
                                                                        .getSimplifiedExpression(inContext: context)
                simplifiedRightExpression = NumberExpressionASTNode.constructed(withValue: -rightValue)
            }
        } else if case let .double(rightValue) = rightValue, rightValue < 0 {
            simplifiedLeftExpression = try NegationExpressionASTNode.constructed(withSubExpression: simplifiedLeftExpression)
                                                                    .getSimplifiedExpression(inContext: context)
            simplifiedRightExpression = NumberExpressionASTNode.constructed(withValue: -rightValue)
        } else if let rightNegationExpression = simplifiedRightExpression as? NegationExpressionASTNode {
            simplifiedLeftExpression = try NegationExpressionASTNode.constructed(withSubExpression: simplifiedLeftExpression)
                                                                    .getSimplifiedExpression(inContext: context)
            simplifiedRightExpression = rightNegationExpression.subExpression
        } else if let rightMultiplicationExpression = simplifiedRightExpression as? MultiplicationExpressionASTNode,
                  let firstValue = (rightMultiplicationExpression.subExpressions.first as? NumberExpressionASTNode)?.value {
            switch firstValue {
            case .integer(..<0), .double(..<0):
                simplifiedLeftExpression = try NegationExpressionASTNode.constructed(withSubExpression: simplifiedLeftExpression)
                                                                        .getSimplifiedExpression(inContext: context)
                simplifiedRightExpression = try rightMultiplicationExpression.getNegatedExpression(inContext: context)
            default: break
            }
        }
        
        return Self.constructed(withLeft: simplifiedLeftExpression, right: simplifiedRightExpression)
    }
    
    func getNegatedExpression(inContext context: SimplificationContext) throws -> any ExpressionASTNode {
        let negatedLeft = try NegationExpressionASTNode.constructed(withSubExpression: self.left)
                                                       .getSimplifiedExpression(inContext: context)
        
        return Self.constructed(withLeft: negatedLeft, right: self.right)
    }
    
    
    var description: String {
        var description = ""
        
        if let binaryLeft = self.left as? any BinaryOperatorExpressionASTNode,
           self.hasHigherOrEqualPrecedence(comparedTo: binaryLeft) {
            description += "(\(binaryLeft))"
        } else {
            description += "\(self.left)"
        }
        
        description += " / "
        
        if let binaryRight = self.right as? any BinaryOperatorExpressionASTNode,
           self.hasHigherOrEqualPrecedence(comparedTo: binaryRight) {
            description += "(\(binaryRight))"
        } else {
            description += "\(self.right)"
        }
        
        return description
    }
}
