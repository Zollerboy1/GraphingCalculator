//
//  ASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

/**
 * A parser for declarations of variables and functions.
 * 
 * This parser correctly parses expressions according to the standard order of operations and allows arbitrarily nested subexpressions.
 * The declaration is parsed into the form of an abstract syntax tree.
 */
class DeclarationParser {
    private let lexer: Lexer
    
    private let declarationString: String
    
    private var previousToken: LexerToken!
    private var currentToken: LexerToken
    
    /**
     * Creates a parser with the given expression string and sets it up for parsing it.
     *
     * - Parameters:
     *   - declarationString: A string containing an unparsed arithmetic expression.
     */
    init(withDeclarationString declarationString: String) {
        self.lexer = Lexer(sourceString: declarationString)
        self.declarationString = declarationString
        self.currentToken = lexer.nextToken()
    }
    
    
    /**
     * Parses the given declaration string into an abstract syntax tree.
     * 
     * The corresponding EBNF rule looks like this:
     * 
     * ```
     * declaration => function_declaration | variable_declaration
     * ```
     *
     * - Returns: The AST node representing the parsed declaration.
     * - Throws: If there was an error while parsing the declaration.
     */
    func parse() throws -> any DeclarationASTNode {
        try self.consume(.identifier, errorMessage: "Expected variable or function declaration name.")
        
        let nameToken = previousToken!
        
        if try self.match(.leftParenthesis) {
            return try parseFunctionDeclaration(withName: nameToken)
        } else if try self.match(.equalsSign) {
            return try parseVariableDeclaration(withName: nameToken)
        }
    
        try self.throwError(withMessage: "Expected a variable or function declaration.")
    }
    
    
    private func parseFunctionDeclaration(withName nameToken: LexerToken) throws -> FunctionDeclarationASTNode {
        let argumentToken = try self.consume(.identifier, errorMessage: "Expected function argument name.")
        
        try self.consume(.rightParenthesis, errorMessage: "Expected ')' after function declaration argument.")
        try self.consume(.equalsSign, errorMessage: "Expected '=' after function declaration argument list.")
    
        let expression = try self.parseExpression()
        
        return FunctionDeclarationASTNode(withToken: nameToken,
                                          functionName: self.tokenString(nameToken),
                                          argumentName: self.tokenString(argumentToken),
                                          expression: expression)
    }
    
    
    private func parseVariableDeclaration(withName nameToken: LexerToken) throws -> VariableDeclarationASTNode {
        let expression = try self.parseExpression()
        
        return VariableDeclarationASTNode(withToken: nameToken,
                                          name: self.tokenString(nameToken),
                                          expression: expression)
    }
    
    
    /**
     * Parses an expression.
     * 
     * The corresponding EBNF rule looks like this:
     * 
     * ```
     * expression => addition_precedence_expression
     * ```
     */
    private func parseExpression() throws -> any ExpressionASTNode {
        let expression = try self.parseAdditionPrecedenceExpression()
    
        guard self.isAtEnd else {
            try self.throwError(withMessage: "Expected the end of the expression.")
        }
    
        return expression
    }
    
    
    /**
     * Parses a subexpression with addition precedence.
     * 
     * The corresponding EBNF rule looks like this:
     * 
     * ```
     * addition_precedence_expression => multiplication_precedence_expression {('+' | '-') multiplication_precedence_expression}
     * ```
     */
    private func parseAdditionPrecedenceExpression() throws -> any ExpressionASTNode {
        let firstNode = try self.parseMultiplicationPrecedenceExpression()
        
        guard try self.match(.operator(type: .additionOrIdentityOperator), .operator(type: .subtractionOrNegationOperator)) else {
            return firstNode
        }
        
        var tokens: [LexerToken] = []
        var subExpressions = [firstNode]
        
        repeat {
            tokens.append(self.previousToken!)
            
            try subExpressions.append(self.parseMultiplicationPrecedenceExpression())
        } while try self.match(.operator(type: .additionOrIdentityOperator), .operator(type: .subtractionOrNegationOperator))
        
        return AdditionExpressionASTNode(withTokens: tokens, subExpressions: subExpressions)
    }
    
    /**
     * Parses a subexpression with multiplication precedence.
     * 
     * The corresponding EBNF rule looks like this:
     * 
     * ```
     * multiplication_precedence_expression => exponentiation_precedence_expression {('*' | '/') exponentiation_precedence_expression}
     * ```
     */
    private func parseMultiplicationPrecedenceExpression() throws -> any ExpressionASTNode {
        let firstNode = try self.parseExponentiationPrecedenceExpression()
        
        var tokens: [LexerToken] = []
        var subExpressions = [firstNode]
        
        while try self.match(.operator(type: .multiplicationOperator), .operator(type: .divisionOperator)) {
            tokens.append(self.previousToken!)
            
            try subExpressions.append(self.parseExponentiationPrecedenceExpression())
        }
        
        return subExpressions[1...].enumerated().reduce(firstNode) { previousNode, element in
            let (index, expression) = element
            let token = tokens[index]
            
            switch token {
            case .source(.operator(.multiplicationOperator), _, _):
                if let multiplicationExpression = previousNode as? MultiplicationExpressionASTNode {
                    return MultiplicationExpressionASTNode(withToken: multiplicationExpression.token,
                                                           subExpressions: multiplicationExpression.subExpressions + [expression])
                } else {
                    return MultiplicationExpressionASTNode(withToken: token, subExpressions: [previousNode, expression])
                }
            case .source(.operator(.divisionOperator), _, _):
                return DivisionExpressionASTNode(withToken: token, left: previousNode, right: expression)
            default:
                fatalError("Unreachable")
            }
        }
    }
    
    /**
     * Parses a subexpression with exponentiation precedence.
     * 
     * The corresponding EBNF rule looks like this:
     * 
     * ```
     * exponentiation_precedence_expression => unary_precedence_expression ['^' unary_precedence_expression]
     * ```
     */
    private func parseExponentiationPrecedenceExpression() throws -> any ExpressionASTNode {
        var node = try self.parseUnaryPrecedenceExpression()
        
        if try self.match(.operator(type: .exponentiationOperator)) {
            let token = previousToken!
            
            let right = try self.parseUnaryPrecedenceExpression()
            
            node = ExponentiationExpressionASTNode(withToken: token, base: node, exponent: right)
        }
        
        return node
    }
    
    /**
     * Parses a subexpression with unary precedence.
     * 
     * The corresponding EBNF rule looks like this:
     * 
     * ```
     * unary_precedence_expression => (('+' | '-') unary_precedence_expression | call_precedence_expression)
     * ```
     */
    private func parseUnaryPrecedenceExpression() throws -> any ExpressionASTNode {
        if try self.match(.operator(type: .additionOrIdentityOperator)) {
            return try self.parseUnaryPrecedenceExpression()
        } else if try self.match(.operator(type: .subtractionOrNegationOperator)) {
            let token = previousToken!
            
            let expression = try self.parseUnaryPrecedenceExpression()
            
            return NegationExpressionASTNode(withToken: token, subExpression: expression)
        }
        
        return try self.parseCallPrecedenceExpression()
    }
    
    /**
     * Parses a subexpression with call precedence.
     * 
     * The corresponding EBNF rule looks like this:
     * 
     * ```
     * call_precedence_expression => primary_expression ['(' addition_precedence_expression ')']
     * ```
     */
    private func parseCallPrecedenceExpression() throws -> any ExpressionASTNode {
        let node = try self.parsePrimaryExpression()
        
        if try self.match(.leftParenthesis) {
            if let variableName = (node as? VariableExpressionASTNode)?.name {
                let function = FunctionCallExpressionASTNode.Function.fromName(name: variableName)
                
                let expression = try self.parseAdditionPrecedenceExpression()
                
                try self.consume(.rightParenthesis, errorMessage: "Expected ')' after function call argument.")
                
                return FunctionCallExpressionASTNode(withToken: node.token, function: function, argument: expression)
            } else {
                try self.throwError(withMessage: "Can only call a function.")
            }
        }
        
        return node
    }
    
    /**
     * Parses a primary expression.
     * 
     * The corresponding EBNF rule looks like this:
     * 
     * ```
     * primary_expression => (number | identifier | grouped_expression)
     * ```
     */
    private func parsePrimaryExpression() throws -> any ExpressionASTNode {
        if try self.match(.numberLiteral) {
            let token = previousToken!
            let value = Double(self.tokenString(token))!
            
            return NumberExpressionASTNode(withToken: token, value: value)
        }
        
        if try self.match(.identifier) {
            let token = previousToken!
            
            return VariableExpressionASTNode(withToken: token, name: self.tokenString(token))
        }
        
        return try self.parseGroupedExpression()
    }
    
    /**
     * Parses a grouped expression.
     * 
     * The corresponding EBNF rule looks like this:
     * 
     * ```
     * grouped_expression => '(' addition_precedence_expression ')'
     * ```
     */
    private func parseGroupedExpression() throws -> any ExpressionASTNode {
        if try self.match(.leftParenthesis) {
            let token = self.previousToken!
            
            let expression = try self.parseAdditionPrecedenceExpression()
            
            try self.consume(.rightParenthesis, errorMessage: "Expected ')' after grouped expression.")
            
            return GroupingExpressionASTNode(withToken: token, subExpression: expression)
        }
        
        try self.throwError(withMessage: "Expected expression.")
    }
    
    
    /**
     * Advances to the next `LexerToken`, assuming the current token has the correct `LexerToken.Type`.
     *
     * - Parameters:
     *   - type: The type that the current token should have.
     * - Parameters:
     *   - errorMessage: The message for the exception that is thrown if the assumption about the current token type was wrong.
     * - Throws: If the current token type is not the given type.
     */
    @discardableResult
    private func consume(_ type: LexerToken.`Type`, errorMessage: String) throws -> LexerToken {
        if self.check(type) {
            try self.advance()
        } else {
            try self.throwError(withMessage: errorMessage)
        }
    
        return self.previousToken
    }
    
    /**
     * Advances to the next `LexerToken`, if the current token has one of the specified `LexerToken.Type`s.
     *
     * - Parameters:
     *   - types: The types that the current token could have.
     * - Returns: True, if the current token had one of the specified types and the parser was advanced, otherwise false.
     */
    private func match(_ types: LexerToken.`Type`...) throws -> Bool {
        for type in types {
            if try self.match(type) {
                return true
            }
        }
        
        return false
    }
    
    /**
     * Advances to the next `LexerToken`, if the current token has the specified `LexerToken.Type`.
     *
     * - Parameters:
     *   - type: The type that the current token could have.
     * - Returns: True, if the current token had the specified type and the parser was advanced, otherwise false.
     */
    private func match(_ type: LexerToken.`Type`) throws -> Bool {
        if self.check(type) {
            try self.advance()
            return true
        }
        
        return false
    }
    
    /**
     * Advances the parser to the next `LexerToken`.
     *
     * - Throws: If the parser is already at the end of the expression or if an error occurred in the lexer.
     */
    private func advance() throws {
        guard !self.isAtEnd else {
            try self.throwError(withMessage: "An unexpected error occurred while parsing.")
        }
        
        self.previousToken = self.currentToken
        self.currentToken = self.lexer.nextToken()
        
        if case let .error(errorType, index) = self.currentToken {
            var message: String
            switch errorType {
            case .invalidCharacter:
                message = "Invalid character at index \(self.index(of: index)).";
            case .noDigitAfterDecimalPoint:
                message = "Expected a digit after the decimal point at index \(self.index(of: index)).";
            case .noDigitAfterE:
                message = "Expected a digit in the floating point exponent at index \(self.index(of: index)).";
            }
            
            try self.throwError(withMessage: message)
        }
    }
    
    /**
     * Checks, if the current `LexerToken` has the specified `LexerToken.Type`.
     *
     * - Parameters:
     *   - type: The type that the current token could have.
     * - Returns: True, if the current token has the specified type, otherwise false.
     */
    private func check(_ type: LexerToken.`Type`) -> Bool {
        if self.isAtEnd { return false }
        
        if case let .source(currentType, _, _) = self.currentToken {
            return currentType == type
        } else {
            fatalError("Can only get string from source token.")
        }
    }
    
    /**
     * Checks, if the parser is already at the end of the expression.
     *
     * - Returns: True, if there are no more tokens, otherwise false.
     */
    private var isAtEnd: Bool {
        if case .endOfInput = self.currentToken {
            return true
        }
        
        return false
    }
    
    
    /**
     * Gives back the substring of the unparsed expression, the specified `LexerToken` corresponds to.
     *
     * - Parameters:
     *   - token: The token of which the corresponding substring should be returned.
     * - Returns: The substring that corresponds to the specified token.
     */
    private func tokenString(_ token: LexerToken) -> Substring {
        if case let .source(_, startIndex, endIndex) = token {
            return self.declarationString[startIndex..<endIndex]
        } else {
            fatalError("Can only get string from source token.")
        }
    }
    
    
    private func throwError(withMessage message: String) throws -> Never {
        throw EvaluationError(message: message)
    }
    
    private func index(of index: String.Index) -> Int {
        self.declarationString.distance(from: self.declarationString.startIndex, to: index)
    }
}
