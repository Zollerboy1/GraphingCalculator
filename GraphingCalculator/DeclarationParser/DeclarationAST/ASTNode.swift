//
//  ASTNode.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

protocol ASTNode: CustomStringConvertible {
    var token: LexerToken { get }
}
