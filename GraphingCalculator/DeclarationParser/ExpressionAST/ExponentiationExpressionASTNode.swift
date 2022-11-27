//
//  ExponentiationExpressionASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 27.11.22.
//

import RealModule

struct ExponentiationExpressionASTNode: BinaryOperatorExpressionASTNode {
    static let precedence = BinaryOperatorPrecedence.exponentiation
    
    let token: LexerToken
    let base, exponent: any ExpressionASTNode
    
    init(withToken token: LexerToken, base: any ExpressionASTNode, exponent: any ExpressionASTNode) {
        guard case .source(.operator(.exponentiationOperator), _, _) = token else {
            fatalError("Wrong token for exponentiation expression.")
        }
        
        self.token = token
        self.base = base
        self.exponent = exponent
    }
    
    private init(constructedWithBase base: any ExpressionASTNode, exponent: any ExpressionASTNode) {
        self.token = .constructed
        self.base = base
        self.exponent = exponent
    }
    
    static func constructed(withBase base: any ExpressionASTNode, exponent: any ExpressionASTNode) -> Self {
        .init(constructedWithBase: base, exponent: exponent)
    }
    
    
    func getValue(inContext context: ExpressionContext) throws -> Double {
        let baseValue = try self.base.getValue(inContext: context)
        let exponentValue = try self.exponent.getValue(inContext: context)
        
        if exponentValue.isInteger {
            return Double.pow(baseValue, Int(exponentValue))
        } else {
            return Double.pow(baseValue, exponentValue)
        }
    }
    
    func checkVariableAccess(withContext context: ExpressionContext) throws {
        try self.base.checkVariableAccess(withContext: context)
        try self.exponent.checkVariableAccess(withContext: context)
    }
    
    func getVariablePowers(withContext context: ExpressionContext) throws -> [Substring: Int]? {
        let exponentValue = try self.exponent.getValue(inContext: context)
        
        guard exponentValue.isInteger,
              var variablePowers = try self.base.getVariablePowers(withContext: context) else {
            return nil
        }
        
        let exponentIntegerValue = Int(exponentValue)
        variablePowers.values.mutateEach { $0 *= exponentIntegerValue }
        
        return variablePowers
    }
    
    
    func getSimplifiedExpression(inContext context: SimplificationContext) throws -> ExpressionASTNode {
        let simplifiedBaseExpression = try self.base.getSimplifiedExpression(inContext: context)
        let simplifiedExponentExpression = try self.exponent.getSimplifiedExpression(inContext: context)
        
        let baseValue = (simplifiedBaseExpression as? NumberExpressionASTNode)?.value
        let exponentValue = (simplifiedExponentExpression as? NumberExpressionASTNode)?.value
        
        if let baseValue, let exponentValue {
            let value: Double
            switch exponentValue {
            case let .integer(integerValue):
                value = Double.pow(baseValue.doubleValue, integerValue)
            case let .double(doubleValue):
                value = Double.pow(baseValue.doubleValue, doubleValue)
            }
            
            return NumberExpressionASTNode.constructed(withValue: value)
        } else if case .integer(1) = baseValue {
            return NumberExpressionASTNode.constructed(withValue: 1)
        } else if let baseExponentiationExpression = simplifiedBaseExpression as? ExponentiationExpressionASTNode {
            let baseExponent = baseExponentiationExpression.exponent
            
            let newBaseExponent: any ExpressionASTNode
            if let multiplicationExpression = baseExponent as? MultiplicationExpressionASTNode {
                newBaseExponent = try multiplicationExpression.withAppendedSubexpression(simplifiedExponentExpression)
                                                              .getSimplifiedExpression(inContext: context)
            } else {
                newBaseExponent = try MultiplicationExpressionASTNode.constructed(withSubExpressions: [baseExponent, simplifiedExponentExpression])
                    .getSimplifiedExpression(inContext: context)
            }
            
            return ExponentiationExpressionASTNode(constructedWithBase: baseExponentiationExpression.base, exponent: newBaseExponent)
        } else if case let .integer(exponentValue) = exponentValue {
            if exponentValue == 0 {
                return NumberExpressionASTNode.constructed(withValue: 1)
            } else if exponentValue == 1 {
                return simplifiedBaseExpression
            }
        }
        
        return Self.constructed(withBase: simplifiedBaseExpression, exponent: simplifiedExponentExpression)
    }
    
    func getNegatedExpression(inContext context: SimplificationContext) throws -> any ExpressionASTNode {
        NegationExpressionASTNode.constructed(withSubExpression: self)
    }
    
    
    var description: String {
        var description = ""
        
        if let binaryBase = self.base as? any BinaryOperatorExpressionASTNode,
           self.hasHigherOrEqualPrecedence(comparedTo: binaryBase) {
            description += "(\(binaryBase))"
        } else {
            description += "\(self.base)"
        }
        
        description += "^"
        
        if let binaryExponent = self.exponent as? any BinaryOperatorExpressionASTNode,
           self.hasHigherOrEqualPrecedence(comparedTo: binaryExponent) {
            description += "(\(binaryExponent))"
        } else {
            description += "\(self.exponent)"
        }
        
        return description
    }
}
