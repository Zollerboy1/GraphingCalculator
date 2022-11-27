//
//  SimplificationContext.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

/**
 * The context for simplifying a declaration or an expression.
 *
 * Contains the declared variables and functions, and a variable substitution that could be used inside the declaration
 * or expression.
 */
class SimplificationContext: ExpressionContext {
    struct VariableSubstitution {
        let name: Substring
        let expression: any ExpressionASTNode
    }
    
    
    private var substitution: VariableSubstitution?
    
    
    override init() {
        super.init()
    }
    
    override init(copying other: ExpressionContext) {
        super.init(copying: other)
        
        if let other = other as? SimplificationContext {
            self.substitution = other.substitution
        }
    }
    
    init(copying other: SimplificationContext) {
        super.init(copying: other)
        
        self.substitution = other.substitution
    }
    
    
    /**
     * Creates a substitution of a variable with the given name by the given expression.
     *
     * - Parameters:
     *   - name: The name of the variable, that will be substituted.
     *   - expression: The expression, the variable with the given name will be substituted by.
     */
    func setSubstitution(forName name: Substring, to expression: any ExpressionASTNode) {
        self.substitution = .init(name: name, expression: expression)
    }
    
    
    /**
     * Gives back, if a variable with the given name has a substitution or not.
     *
     * - Parameters:
     *   - name: The name of the variable that should be searched for.
     * - Returns: True if the variable has a substitution in this context, otherwise false.
     */
    func getSubstitution(forName name: Substring) -> VariableSubstitution? {
        return self.substitution?.name == name ? self.substitution : nil
    }
}
