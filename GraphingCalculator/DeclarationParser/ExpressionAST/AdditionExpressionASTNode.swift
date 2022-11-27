//
//  AdditionExpressionASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 27.11.22.
//

struct AdditionExpressionASTNode: BinaryOperatorExpressionASTNode {
    typealias SubExpression = (expression: any ExpressionASTNode, isNegated: Bool)
    
    static let precedence = BinaryOperatorPrecedence.addition
    
    let token: LexerToken
    let subExpressions: [SubExpression]
    
    init(withTokens tokens: [LexerToken], subExpressions: [any ExpressionASTNode]) {
        guard let firstToken = tokens.first,
              let firstSubExpression = subExpressions.first,
              subExpressions.count == tokens.count + 1 else {
            fatalError("Incorrect number of sub expressions for addition expression.")
        }
        
        let types = tokens.compactMap {
            if case let .source(.operator(type), _, _) = $0,
               type == .additionOrIdentityOperator || type == .subtractionOrNegationOperator {
                return type
            } else {
                return nil
            }
        }
        
        guard tokens.count == types.count else {
            fatalError("Wrong token for addition expression.")
        }
        
        self.token = firstToken
        self.subExpressions = [(firstSubExpression, false)] + zip(subExpressions.dropFirst(), types).map { expression, type in
            (expression, type == .subtractionOrNegationOperator)
        }
    }
    
    private init(constructedWithSubExpressions subExpressions: [SubExpression]) {
        self.token = .constructed
        self.subExpressions = subExpressions
    }
    
    static func constructed(withSubExpressions subExpressions: [SubExpression]) -> Self {
        .init(constructedWithSubExpressions: subExpressions)
    }
    
    
    func withAppendedSubexpression(_ expression: any ExpressionASTNode, isNegated: Bool) -> Self {
        .init(constructedWithSubExpressions: self.subExpressions + [(expression, isNegated)])
    }
    
    
    func getValue(inContext context: ExpressionContext) throws -> Double {
        try self.subExpressions.map { expression, isNegated in
            try expression.getValue(inContext: context) * (isNegated ? -1 : 1)
        }.reduce(0, +)
    }
    
    func checkVariableAccess(withContext context: ExpressionContext) throws {
        for (expression, _) in self.subExpressions {
            try expression.checkVariableAccess(withContext: context)
        }
    }
    
    func getVariablePowers(withContext context: ExpressionContext) throws -> [Substring: Int]? {
        return nil
    }
    
    
    func getSimplifiedExpression(inContext context: SimplificationContext) throws -> any ExpressionASTNode {
        var simplifiedSubExpressions: [SubExpression] = try self.subExpressions.flatMap {
            let simplifiedExpression = try $0.expression.getSimplifiedExpression(inContext: context)
            switch simplifiedExpression {
            case let negationExpression as NegationExpressionASTNode:
                return [(negationExpression.subExpression, !$0.isNegated)]
            case let additionExpression as AdditionExpressionASTNode:
                return additionExpression.subExpressions
            default:
                return [(simplifiedExpression, $0.isNegated)]
            }
        }
        
        let numberValue = simplifiedSubExpressions.extractAllMapped { expression, isNegated in
            ((expression as? NumberExpressionASTNode)?.value.doubleValue).map { $0 * (isNegated ? -1 : 1) }
        }.reduce(0, +)
        
        let numberExpression = NumberExpressionASTNode.constructed(withValue: numberValue)
        
        guard !simplifiedSubExpressions.isEmpty else {
            return numberExpression
        }
        
        
        var newSubExpressions: [SubExpression] = []
        if case .integer(0) = numberExpression.value {} else {
            newSubExpressions.append((numberExpression, false))
        }
        
        newSubExpressions.append(contentsOf: simplifiedSubExpressions)
        
        if newSubExpressions.count == 1 {
            if newSubExpressions.first!.isNegated {
                return try NegationExpressionASTNode.constructed(withSubExpression: newSubExpressions.first!.expression)
                                                    .getSimplifiedExpression(inContext: context)
            } else {
                return newSubExpressions.first!.expression
            }
        } else {
            return Self.constructed(withSubExpressions: newSubExpressions)
        }
    }
    
    func getNegatedExpression(inContext context: SimplificationContext) throws -> any ExpressionASTNode {
        Self.constructed(withSubExpressions: self.subExpressions.map { ($0.expression, !$0.isNegated) })
    }
    
    
    var description: String {
        var description = self.subExpressions.first!.isNegated ? "-" : ""
        
        if let binaryExpression = self.subExpressions.first?.expression as? BinaryOperatorExpressionASTNode,
           self.hasHigherOrEqualPrecedence(comparedTo: binaryExpression) {
            description += "(\(binaryExpression))"
        } else {
            description += "\(self.subExpressions.first!.expression)"
        }
        
        return description + self.subExpressions[1...].map {
            let prefix = $0.isNegated ? " - " : " + "
            if let binaryExpression = $0.expression as? BinaryOperatorExpressionASTNode,
               self.hasHigherOrEqualPrecedence(comparedTo: binaryExpression) {
                return "\(prefix)(\(binaryExpression))"
            } else {
                return "\(prefix)\($0.expression)"
            }
        }.joined()
    }
}
