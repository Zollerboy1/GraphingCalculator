//
//  MainView.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 16.12.21.
//

import SwiftUI


struct MainView: View {
    @StateObject var state = GraphState()
    @State var sidebarWidth: Double = 400
    
    
    var body: some View {
        ZStack(alignment: .leading) {
            GraphView(sidebarWidth: self.$sidebarWidth)
            SidebarView(width: self.$sidebarWidth)
        }
        .environmentObject(state)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
