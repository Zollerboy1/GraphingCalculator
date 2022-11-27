//
//  Declaration.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

import SwiftUI


struct Declaration {
    enum Storage {
        case function(declaration: FunctionDeclarationASTNode)
        case variable(declaration: VariableDeclarationASTNode)
        case error(message: String)
    }
    
    
    let storage: Storage
    
    
    init?(parsedFrom string: String, withContext context: SimplificationContext) {
        guard !string.isEmpty else { return nil }
        
        var storage: Storage
        do {
            let parser = DeclarationParser(withDeclarationString: string)
            let declaration = try parser.parse().getSimplifiedDeclaration(inContext: context)
            
            print(declaration)
            
            if let functionDeclaration = declaration as? FunctionDeclarationASTNode {
                let contextCopy = SimplificationContext(copying: context)
                contextCopy.setVariable(withName: functionDeclaration.argumentName, to: 0)
                
                try functionDeclaration.expression.checkVariableAccess(withContext: contextCopy)
                
                storage = .function(declaration: functionDeclaration)
                
                context.setFunction(withName: functionDeclaration.functionName, to: functionDeclaration)
            } else if let variableDeclaration = declaration as? VariableDeclarationASTNode {
                try variableDeclaration.expression.checkVariableAccess(withContext: context)
                
                storage = .variable(declaration: variableDeclaration)
                
                let variableValue = try variableDeclaration.expression.getValue(inContext: context)
                
                context.setVariable(withName: variableDeclaration.name, to: variableValue)
            } else {
                return nil
            }
        } catch let error as UnknownNameError {
            switch error {
            case let .variable(name):
                storage = .error(message: "Unknown variable '\(name)'.")
            case let .function(name):
                storage = .error(message: "Unknown function '\(name)'.")
            }
        } catch let error as EvaluationError {
            storage = .error(message: error.message)
        } catch is DivisionByZeroError {
            storage = .error(message: "Division by zero")
        } catch {
            fatalError(error.localizedDescription)
        }
        
        self.storage = storage
    }
    
    func add(toContext context: SimplificationContext) {
        switch self.storage {
        case let .function(functionDeclaration):
            context.setFunction(withName: functionDeclaration.functionName, to: functionDeclaration)
        case let .variable(variableDeclaration):
            let variableValue = try! variableDeclaration.expression.getValue(inContext: context)
            
            context.setVariable(withName: variableDeclaration.name, to: variableValue)
        default:
            break
        }
    }
}
