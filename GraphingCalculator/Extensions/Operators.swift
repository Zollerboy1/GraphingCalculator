//
//  Operators.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 17.12.21.
//


precedencegroup OptionalChainingAdditionPrecedence {
    associativity: left
    higherThan: NilCoalescingPrecedence
}

precedencegroup OptionalChainingMultiplicationPrecedence {
    associativity: left
    higherThan: OptionalChainingAdditionPrecedence
}


infix operator ?+: OptionalChainingAdditionPrecedence
infix operator ?-: OptionalChainingAdditionPrecedence
infix operator ?*: OptionalChainingMultiplicationPrecedence
infix operator ?/: OptionalChainingMultiplicationPrecedence


func ?+<T: AdditiveArithmetic>(lhs: T?, rhs: @autoclosure () -> T) -> T? {
    guard let lhs = lhs else { return nil }
    
    return lhs + rhs()
}

func ?+<T: AdditiveArithmetic>(lhs: T, rhs: T?) -> T? {
    guard let rhs = rhs else { return nil }
    
    return lhs + rhs
}


func ?-<T: AdditiveArithmetic>(lhs: T?, rhs: @autoclosure () -> T) -> T? {
    guard let lhs = lhs else { return nil }
    
    return lhs - rhs()
}

func ?-<T: AdditiveArithmetic>(lhs: T, rhs: T?) -> T? {
    guard let rhs = rhs else { return nil }
    
    return lhs - rhs
}


func ?*<T: Numeric>(lhs: T?, rhs: @autoclosure () -> T) -> T? {
    guard let lhs = lhs else { return nil }
    
    return lhs * rhs()
}

func ?*<T: Numeric>(lhs: T, rhs: T?) -> T? {
    guard let rhs = rhs else { return nil }
    
    return lhs * rhs
}



func ?/<T: BinaryInteger>(lhs: T?, rhs: @autoclosure () -> T) -> T? {
    guard let lhs = lhs else { return nil }
    
    return lhs / rhs()
}

func ?/<T: BinaryInteger>(lhs: T, rhs: T?) -> T? {
    guard let rhs = rhs else { return nil }
    
    return lhs / rhs
}


func ?/<T: FloatingPoint>(lhs: T?, rhs: @autoclosure () -> T) -> T? {
    guard let lhs = lhs else { return nil }
    
    return lhs / rhs()
}

func ?/<T: FloatingPoint>(lhs: T, rhs: T?) -> T? {
    guard let rhs = rhs else { return nil }
    
    return lhs / rhs
}

