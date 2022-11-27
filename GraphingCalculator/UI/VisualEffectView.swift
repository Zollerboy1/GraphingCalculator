//
//  VisualEffectView.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 18.12.21.
//

import SwiftUI


struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: NSViewRepresentableContext<Self>) -> NSVisualEffectView {
        NSVisualEffectView()
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: NSViewRepresentableContext<Self>) {
        nsView.material = self.material
        nsView.blendingMode = self.blendingMode
    }
}
