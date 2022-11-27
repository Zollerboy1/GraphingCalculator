//
//  FormattedTextFieldStyle.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

import SwiftUI


enum FormattedTextFieldStyle {
    case plain
    case squareBorder
    case roundedBorder
}


struct FormattedTextFieldStyleKey: EnvironmentKey {
    static var defaultValue = FormattedTextFieldStyle.squareBorder
}


extension EnvironmentValues {
    var formattedTextFieldStyle: FormattedTextFieldStyle {
        get { self[FormattedTextFieldStyleKey.self] }
        set { self[FormattedTextFieldStyleKey.self] = newValue }
    }
}


extension View {
    func formattedTextFieldStyle(_ style: FormattedTextFieldStyle) -> some View {
        self.environment(\.formattedTextFieldStyle, style)
    }
}
