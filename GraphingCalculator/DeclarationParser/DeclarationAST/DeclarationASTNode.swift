//
//  DeclarationASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

protocol DeclarationASTNode: ASTNode {
    /**
     * Gives back a declaration, the expression of which is simplified as much as possible.
     *
     * - Parameters:
     *   - context: The context that contains other variable and function declarations, as well as at most one variable
     *                substitution needed for the simplification.
     * - Returns: A declaration AST node with a simplified expression.
     * - Throws: If some error occurs during the simplification.
     */
    func getSimplifiedDeclaration(inContext context: SimplificationContext) throws -> Self
}
