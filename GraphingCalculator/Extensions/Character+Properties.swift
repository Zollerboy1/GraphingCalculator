//
//  Character+Properties.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

extension Character {
    private func belongsToOneCategory(of categories: [Unicode.GeneralCategory]) -> Bool {
        if self.isASCII {
            let scalar = self.unicodeScalars.first!
            
            for category in categories {
                if scalar.properties.generalCategory == category {
                    return true
                }
            }
        }
        
        return false
    }
    
    var isDigit: Bool {
        self.belongsToOneCategory(of: [.decimalNumber])
    }
    
    var isLetter: Bool {
        self.belongsToOneCategory(of: [.lowercaseLetter, .uppercaseLetter])
    }
    
    var isIdentifierCharacter: Bool {
        self.belongsToOneCategory(of: [.decimalNumber, .lowercaseLetter, .uppercaseLetter]) || self == "_"
    }
    
    var isIdentifierHead: Bool {
        self.isLetter || self == "_"
    }
    
    
    var convertedToMathFont: Character {
        if let scalar = self.unicodeScalars.first {
            let newValue: UInt32
            switch scalar.value {
            case 0x41...0x5A:
                newValue = scalar.value + 0x1D3F3
            case 0x61...0x67, 0x69...0x7A:
                newValue = scalar.value + 0x1D3ED
            case 0x68:
                newValue = 0x210E
            default:
                return self
            }
            
            return .init(.init(String.UnicodeScalarView.init([.init(newValue)!] + self.unicodeScalars.dropFirst())))
        } else {
            return self
        }
    }
    
    var convertedToNormalFont: Character {
        if let scalar = self.unicodeScalars.first {
            let newValue: UInt32
            switch scalar.value {
            case 0x1D434...0x1D44D:
                newValue = scalar.value - 0x1D3F3
            case 0x1D44E...0x1D467:
                newValue = scalar.value - 0x1D3ED
            case 0x210E:
                newValue = 0x68
            default:
                return self
            }
            
            return .init(.init(String.UnicodeScalarView.init([.init(newValue)!] + self.unicodeScalars.dropFirst())))
        } else {
            return self
        }
    }
}
