//
//  ExpressionContext.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

/**
 * The context for evaluating an expression.
 *
 * Contains the declared variables and functions that could be used inside the expression.
 */
class ExpressionContext {
    struct Variable {
        let name: Substring
        let value: Double
    }
    
    private var variables: [Substring: Double]
    private var functions: [Substring: FunctionDeclarationASTNode]
    
    init() {
        self.variables = .init()
        self.functions = .init()
    }
    
    init(copying other: ExpressionContext) {
        self.variables = other.variables
        self.functions = other.functions
    }
    
    
    /**
     * Creates a variable with the given name and value or updates the value of an already existing variable with this name.
     *
     * - Parameters:
     *   - name: The name of the variable, the value of which will be set to the given value.
     *   - value: The value to set the variable with the given name to.
     */
    func setVariable(withName name: Substring, to value: Double) {
        variables[name] = value
    }
    
    
    /**
     * Gives back the variable with the given name.
     *
     * - Parameters:
     *   - name: The name of the variable that should be searched for.
     * - Returns: A `Variable` value if the variable exists in this context, otherwise `nil`.
     */
    func getVariable(withName name: Substring) -> Variable? {
        guard let value = variables[name] else {
            return nil
        }
        
        return .init(name: name, value: value)
    }
    
    
    /**
     * Gives back the value of the variable with the given name.
     *
     * - Parameters:
     *   - name: The name of the variable, the value of which should be given back.
     * - Returns: The value of the variable with the given name.
     * - Throws: If a variable with the given name does not exist.
     */
    func getValueOfVariable(withName name: Substring) throws -> Double {
        guard let value = variables[name] else {
            throw UnknownNameError.variable(name: name)
        }
        
        return value
    }
    
    
    /**
     * Creates a function with the given name and declaration or updates the declaration of an already existing function with this name.
     *
     * - Parameters:
     *   - name: The name of the function, the declaration of which will be set to the given declaration.
     *   - declaration: The declaration to set the function with the given name to.
     */
    func setFunction(withName name: Substring, to declaration: FunctionDeclarationASTNode) {
        functions[name] = declaration
    }
    
    
    /**
     * Gives back the function with the given name.
     *
     * - Parameters:
     *   - name: The name of the function that should be searched for.
     * - Returns: The `FunctionDeclarationASTNode` value if the function exists in this context, otherwise `nil`.
     */
    func getFunction(withName name: Substring) -> FunctionDeclarationASTNode? {
        return functions[name]
    }
    
    
    /**
     * Gives back the value of the function with the given name for the specified argument.
     *
     * - Parameters:
     *   - name: The name of the function, the value of which should be given back.
     *   - argument: The argument for which the function should be evaluated.
     * - Returns: The value of the function with the given name for the specified argument.
     * - Throws: If a function with the given name does not exist, or if the evaluation fails.
     */
    func getValueOfFunction(withName name: Substring, argument: Double) throws -> Double {
        guard let declaration = functions[name] else {
            throw UnknownNameError.function(name: name)
        }
        
        let functionContext = ExpressionContext(copying: self)
        functionContext.setVariable(withName: declaration.argumentName, to: argument)
        
        return try declaration.expression.getValue(inContext: functionContext)
    }
}
