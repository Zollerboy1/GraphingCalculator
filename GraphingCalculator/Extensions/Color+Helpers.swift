//
//  Color+Helpers.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 05.07.22.
//

import AppKit
import SwiftUI

extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB)!
        
        return (nsColor.redComponent, nsColor.greenComponent, nsColor.blueComponent, nsColor.alphaComponent)
    }
    
    func shaded(by factor: Double) -> Color {
        let (red, green, blue, opacity) = self.components
        
        let newRed = red * (1 - factor)
        let newGreen = green * (1 - factor)
        let newBlue = blue * (1 - factor)
        
        return .init(red: newRed, green: newGreen, blue: newBlue, opacity: opacity)
    }
    
    func tinted(by factor: Double) -> Color {
        let (red, green, blue, opacity) = self.components
        
        let newRed = red + (1 - red) * factor
        let newGreen = green + (1 - green) * factor
        let newBlue = blue + (1 - green) * factor
        
        return .init(red: newRed, green: newGreen, blue: newBlue, opacity: opacity)
    }
}
