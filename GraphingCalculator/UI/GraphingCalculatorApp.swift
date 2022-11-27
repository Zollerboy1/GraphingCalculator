//
//  GraphingCalculatorApp.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 16.12.21.
//

import SwiftUI


@main
struct GraphingCalculatorApp: App {
    @NSApplicationDelegateAdaptor(GraphingCalculatorAppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 1200, maxWidth: .infinity, minHeight: 720, maxHeight: .infinity)
        }
    }
}


class GraphingCalculatorAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
