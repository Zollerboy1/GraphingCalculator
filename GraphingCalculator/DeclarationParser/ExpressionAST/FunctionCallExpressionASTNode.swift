//
//  FunctionCallExpressionASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

import RealModule

/**
 * An AST node representing a function call and its argument.
 */
struct FunctionCallExpressionASTNode: ExpressionASTNode {
    /**
     * A class, an instance of which represents either a builtin or a user-defined function that should be called.
     */
    enum Function: CustomStringConvertible {
        case sine
        case cosine
        case tangent
        case absoluteValue
        case squareRoot
        case logarithm
        case custom(name: Substring)
    
        static func fromName(name: Substring) -> Function {
            switch (name) {
            case "sin":
                return .sine
            case "cos":
                return .cosine
            case "tan":
                return .tangent
            case "abs":
                return .absoluteValue
            case "sqrt":
                return .squareRoot
            case "log":
                return .logarithm
            default:
                return .custom(name: name)
            }
        }
        
        
        func getValue(inContext context: ExpressionContext, withArgument argumentValue: Double) throws -> Double {
            switch self {
            case .sine:
                return Double.sin(argumentValue)
            case .cosine:
                return Double.cos(argumentValue)
            case .tangent:
                return Double.tan(argumentValue)
            case .absoluteValue:
                return argumentValue.magnitude
            case .squareRoot:
                return Double.sqrt(argumentValue)
            case .logarithm:
                return Double.log(argumentValue)
            case let .custom(name):
                return try context.getValueOfFunction(withName: name, argument: argumentValue)
            }
        }
        
        func checkVariableAccess(withContext context: ExpressionContext) throws {
            switch self {
            case let .custom(name):
                _ = try context.getValueOfFunction(withName: name, argument: 0)
            default:
                break
            }
        }
    
    
        var description: String {
            switch self {
            case .sine:
                return "sin"
            case .cosine:
                return "cos"
            case .tangent:
                return "tan"
            case .absoluteValue:
                return "abs"
            case .squareRoot:
                return "sqrt"
            case .logarithm:
                return "log"
            case let .custom(name):
                return String(name)
            }
        }
    }
    
    
    let token: LexerToken
    let function: Function
    let argument: any ExpressionASTNode
    
    init(withToken token: LexerToken, function: Function, argument: any ExpressionASTNode) {
        self.token = token
        self.function = function
        self.argument = argument
    }
    
    private init(constructedWithFunction function: Function, argument: any ExpressionASTNode) {
        self.token = .constructed
        self.function = function
        self.argument = argument
    }
    
    static func constructed(withFunction function: Function, argument: any ExpressionASTNode) -> Self {
        .init(constructedWithFunction: function, argument: argument)
    }
    
    
    func getValue(inContext context: ExpressionContext) throws -> Double {
        let argumentValue = try self.argument.getValue(inContext: context)
        
        return try self.function.getValue(inContext: context, withArgument: argumentValue)
    }
    
    func checkVariableAccess(withContext context: ExpressionContext) throws {
        try self.function.checkVariableAccess(withContext: context)
        try self.argument.checkVariableAccess(withContext: context)
    }
    
    func getVariablePowers(withContext context: ExpressionContext) -> [Substring: Int]? {
        [:]
    }
    
    
    func getSimplifiedExpression(inContext context: SimplificationContext) throws -> any ExpressionASTNode {
        let simplifiedArgument = try self.argument.getSimplifiedExpression(inContext: context)
        
        if let argumentValue = (simplifiedArgument as? NumberExpressionASTNode)?.value.doubleValue {
            return try NumberExpressionASTNode.constructed(withValue: self.function.getValue(inContext: context, withArgument: argumentValue))
        } else if case let .custom(name) = self.function,
                  let functionDeclaration = context.getFunction(withName: name) {
            return try functionDeclaration.getSimplifiedExpression(inContext: context, withAppliedSubstitution: simplifiedArgument)
        }
        
        return FunctionCallExpressionASTNode.constructed(withFunction: self.function, argument: simplifiedArgument)
    }
    
    
    var description: String {
        "\(self.function)(\(self.argument))"
    }
}
