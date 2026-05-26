//
//  MDQuickViewApp.swift
//  MDQuickView
//
//  Created by Turek on 26/05/2026.
//

import SwiftUI

@main
struct MDQuickViewApp: App {
    var body: some Scene {
        // Single, minimal window sized to its content.
        Window("MDQuickView", id: "main") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
