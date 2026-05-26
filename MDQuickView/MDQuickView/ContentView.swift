//
//  ContentView.swift
//  MDQuickView
//
//  Created by Turek on 26/05/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 128, height: 128)
                .accessibilityLabel("MDQuickView app icon")
            Text("MDQuickView")
                .font(.title)
                .fontWeight(.semibold)
            // The single line that tells the user what the app does and how to use it.
            Text("Quick Look extensions are installed — press Space on a Markdown file in Finder to preview it.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(width: 420)
    }
}

#Preview {
    ContentView()
}
