//
//  FormattedTextField.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

import SwiftUI


struct FormattedTextField<Formatter>: View where Formatter: TextFieldFormatter {
    private let formatter: Formatter
    private let placeholder: String?
    private let font: NSFont?
    private let textColor: Color?
    
    @Binding private var value: Formatter.Value

    init(value: Binding<Formatter.Value>, formatter: Formatter, placeholder: String? = nil, font: NSFont? = nil, textColor: Color? = nil) {
        self._value = value
        self.formatter = formatter
        self.placeholder = placeholder
        self.font = font
        self.textColor = textColor
    }

    public var body: some View {
        FormattedTextFieldRepresentable(value: self.$value, formatter: self.formatter, placeholder: self.placeholder, font: self.font, textColor: self.textColor)
    }
}

struct FormattedTextFieldRepresentable<Formatter>: NSViewRepresentable where Formatter: TextFieldFormatter {
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: FormattedTextFieldRepresentable
        
        var isEditing = false
        
        weak var textField: NSTextField?
        
        init(_ parent: FormattedTextFieldRepresentable) {
            self.parent = parent
        }
        
        
        
        func controlTextDidBeginEditing(_ notification: Notification) {
            if let textField = self.textField, textField == notification.object as? NSTextField {
                self.isEditing = true
                
                textField.stringValue = self.parent.formatter.editingString(for: self.parent.value)
            }
        }
        
        func controlTextDidChange(_ notification: Notification) {
            if let textField = self.textField, textField == notification.object as? NSTextField {
                let string = textField.stringValue
                
                self.parent.value = self.parent.formatter.value(from: string)
                
                if self.isEditing {
                    textField.stringValue = self.parent.formatter.editingString(for: self.parent.value)
                } else {
                    textField.stringValue = self.parent.formatter.displayString(for: self.parent.value)
                }
            }
        }
        
        func controlTextDidEndEditing(_ notification: Notification) {
            if let textField = self.textField, textField == notification.object as? NSTextField {
                self.isEditing = false
                
                textField.stringValue = self.parent.formatter.displayString(for: self.parent.value)
            }
        }
    }
    
    
    @Environment(\.formattedTextFieldStyle) var style
    
    private let formatter: Formatter
    private let placeholder: String?
    private let font: NSFont?
    private let textColor: Color?
    
    @Binding private var value: Formatter.Value
    
    init(value: Binding<Formatter.Value>, formatter: Formatter, placeholder: String?, font: NSFont?, textColor: Color?) {
        self._value = value
        self.formatter = formatter
        self.placeholder = placeholder
        self.font = font
        self.textColor = textColor
    }
    
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        
        textField.placeholderString = self.placeholder
        
        if let font = self.font {
            textField.font = font
        }
        
        if let textColor = self.textColor {
            textField.textColor = .init(textColor)
        }
        
        switch self.style {
        case .plain:
            textField.drawsBackground = true
            textField.backgroundColor = .clear
            textField.isBezeled = false
            textField.focusRingType = .none
            textField.bezelStyle = .squareBezel
        case .squareBorder:
            textField.drawsBackground = false
            textField.isBezeled = true
            textField.focusRingType = .default
            textField.bezelStyle = .squareBezel
        case .roundedBorder:
            textField.drawsBackground = false
            textField.isBezeled = true
            textField.focusRingType = .default
            textField.bezelStyle = .roundedBezel
        }
        
        textField.delegate = context.coordinator
        context.coordinator.textField = textField
        
        return textField
    }
    
    func updateNSView(_ textField: NSTextField, context: Context) {
        textField.placeholderString = self.placeholder
        
        if let font = self.font {
            textField.font = font
        }
        
        if let textColor = self.textColor {
            textField.textColor = .init(textColor)
        }
        
        switch self.style {
        case .plain:
            textField.drawsBackground = true
            textField.backgroundColor = .clear
            textField.isBezeled = false
            textField.focusRingType = .none
            textField.bezelStyle = .squareBezel
        case .squareBorder:
            textField.drawsBackground = false
            textField.isBezeled = true
            textField.focusRingType = .default
            textField.bezelStyle = .squareBezel
        case .roundedBorder:
            textField.drawsBackground = false
            textField.isBezeled = true
            textField.focusRingType = .default
            textField.bezelStyle = .roundedBezel
        }
    }
    
    
    func makeCoordinator() -> Coordinator {
        .init(self)
    }
}
