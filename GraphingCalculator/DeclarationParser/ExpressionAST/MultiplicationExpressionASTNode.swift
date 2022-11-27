//
//  MultiplicationExpressionASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 27.11.22.
//

struct MultiplicationExpressionASTNode: BinaryOperatorExpressionASTNode {
    static let precedence = BinaryOperatorPrecedence.multiplication
    
    let token: LexerToken
    let subExpressions: [any ExpressionASTNode]
    
    init(withToken token: LexerToken, subExpressions: [any ExpressionASTNode]) {
        guard subExpressions.count >= 2 else {
            fatalError("Incorrect number of sub expressions for multiplication expression.")
        }
        
        guard case .source(.operator(.multiplicationOperator), _, _) = token else {
            fatalError("Wrong token for multiplication expression.")
        }
        
        self.token = token
        self.subExpressions = subExpressions
    }
    
    private init(constructedWithSubExpressions subExpressions: [any ExpressionASTNode]) {
        self.token = .constructed
        self.subExpressions = subExpressions
    }
    
    static func constructed(withSubExpressions subExpressions: [any ExpressionASTNode]) -> Self {
        .init(constructedWithSubExpressions: subExpressions)
    }
    
    
    func withAppendedSubexpression(_ expression: any ExpressionASTNode) -> Self {
        .init(constructedWithSubExpressions: self.subExpressions + [expression])
    }
    
    
    func getValue(inContext context: ExpressionContext) throws -> Double {
        try self.subExpressions.map{
            try $0.getValue(inContext: context)
        }.reduce(1, *)
    }
    
    func checkVariableAccess(withContext context: ExpressionContext) throws {
        for expression in self.subExpressions {
            try expression.checkVariableAccess(withContext: context)
        }
    }
    
    func getVariablePowers(withContext context: ExpressionContext) throws -> [Substring: Int]? {
        var variablePowers: [Substring: Int] = [:]
        for subExpression in self.subExpressions {
            if let powers = try subExpression.getVariablePowers(withContext: context) {
                variablePowers.merge(powers, uniquingKeysWith: +)
            } else {
                return nil
            }
        }
        
        return variablePowers
    }
    
    
    func getSimplifiedExpression(inContext context: SimplificationContext) throws -> any ExpressionASTNode {
        var isNegated = false
        var simplifiedSubExpressions = try self.subExpressions.flatMap {
            let simplifiedExpression = try $0.getSimplifiedExpression(inContext: context)
            switch simplifiedExpression {
            case let negationExpression as NegationExpressionASTNode:
                isNegated.toggle()
                return [negationExpression.subExpression]
            case let multiplicationExpression as MultiplicationExpressionASTNode:
                return multiplicationExpression.subExpressions
            default:
                return [simplifiedExpression]
            }
        }
        
        let numberValue = simplifiedSubExpressions.extractAllMapped {
            ($0 as? NumberExpressionASTNode)?.value.doubleValue
        }.reduce(isNegated ? -1 : 1, *)
        
        let numberExpression = NumberExpressionASTNode.constructed(withValue: numberValue)
        
        guard !(simplifiedSubExpressions.isEmpty || numberValue.isApproximatelyEqual(to: 0)) else {
            return numberExpression
        }
        
        
        var variablePowers = simplifiedSubExpressions.extractAllMapped {
            ($0 as? VariableExpressionASTNode)?.name
        }.reduce(into: [:]) {
            $0[$1, default: 0] += 1
        }
        
        variablePowers.merge(simplifiedSubExpressions.extractAllMapped {
            if let exponentiationExpression = $0 as? ExponentiationExpressionASTNode,
               let variableExpression = exponentiationExpression.base as? VariableExpressionASTNode,
               let numberExpression = exponentiationExpression.exponent as? NumberExpressionASTNode,
               case let .integer(power) = numberExpression.value {
                return (variableExpression.name, power)
            } else {
                return nil
            }
        }, uniquingKeysWith: +)
        
        
        var newSubExpressions: [any ExpressionASTNode] = []
        if case .integer(1) = numberExpression.value {} else {
            newSubExpressions.append(numberExpression)
        }
        
        newSubExpressions.append(contentsOf: variablePowers.map { name, power in
            let base = VariableExpressionASTNode.constructed(withName: name)
            
            if power == 1 {
                return base
            } else {
                let exponent = NumberExpressionASTNode.constructed(withValue: Double(power))
                return ExponentiationExpressionASTNode.constructed(withBase: base, exponent: exponent)
            }
        })
        
        newSubExpressions.append(contentsOf: simplifiedSubExpressions)
        
        if newSubExpressions.count == 1 {
            return newSubExpressions.first!
        } else {
            return Self.constructed(withSubExpressions: newSubExpressions)
        }
    }
    
    func getNegatedExpression(inContext context: SimplificationContext) throws -> any ExpressionASTNode {
        var newSubExpressions = self.subExpressions
        if let firstValue = (newSubExpressions.first as? NumberExpressionASTNode)?.value {
            switch firstValue {
            case .integer(-1):
                newSubExpressions.removeFirst()
            case let .integer(integerValue):
                newSubExpressions[0] = NumberExpressionASTNode.constructed(withValue: -integerValue)
            case let .double(doubleValue):
                newSubExpressions[0] = NumberExpressionASTNode.constructed(withValue: -doubleValue)
            }
        } else {
            newSubExpressions.insert(NumberExpressionASTNode.constructed(withValue: -1), at: 0)
        }
        
        if newSubExpressions.count == 1 {
            return newSubExpressions.first!
        } else {
            return Self.constructed(withSubExpressions: newSubExpressions)
        }
    }
    
    
    var description: String {
        return self.subExpressions.map {
            if let binaryExpression = $0 as? BinaryOperatorExpressionASTNode,
               self.hasHigherOrEqualPrecedence(comparedTo: binaryExpression) {
                return "(\(binaryExpression))"
            } else {
                return "\($0)"
            }
        }.joined(separator: " * ")
    }
}
