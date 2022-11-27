//
//  ExpressionASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

/**
 * A node of an abstract syntax tree which represents a parsed expression or subexpression.
 */
protocol ExpressionASTNode: ASTNode {
    /**
     * Evaluates the expression or subexpression represented by this node and returns the resulting value.
     *
     * - Parameters:
     *   - context: The context in which the expression or subexpression should be evaluated.
     * - Returns: The resulting value as a double.
     * - Throws: If there went something wrong while evaluating the expression or subexpression.
     */
    func getValue(inContext context: ExpressionContext) throws -> Double
    
    func checkVariableAccess(withContext context: ExpressionContext) throws
    
    /**
     * Gives back the power of each variable occuring in this expression.
     *
     * - Parameters:
     *   - context: The context in which the expression or subexpression should be evaluated.
     * - Returns: A dictionary of variable names and their respective powers in this expression, if applicable to this expression.
     */
    func getVariablePowers(withContext context: ExpressionContext) throws -> [Substring: Int]?
    
    
    /**
     * Gives back a expression, which is a simplified version of this expression.
     *
     * - Parameters:
     *   - context: The context that contains variable and function declarations, as well as at most one variable
     *                substitution needed for the simplification.
     * - Returns: An expression AST node which is simplified as much as possible.
     * - Throws: If some error occurs during the simplification.
     */
    func getSimplifiedExpression(inContext context: SimplificationContext) throws -> any ExpressionASTNode
}
