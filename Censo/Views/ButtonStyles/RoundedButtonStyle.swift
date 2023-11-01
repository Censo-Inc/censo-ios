//
//  RoundedButtonStyle.swift
//  Censo
//
//  Created by Ben Holzman on 10/10/23.
//

import SwiftUI

struct RoundedButtonStyle: ButtonStyle {
    var tint = ButtonStyleTint.dark
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        RoundedButton(configuration: configuration, tint: tint)
    }
    
    struct RoundedButton: View {
        let configuration: ButtonStyle.Configuration
        var tint: ButtonStyleTint
        
        @Environment(\.isEnabled) private var isEnabled: Bool
        
        var body: some View {
            configuration.label
                .padding()
                .foregroundColor(isEnabled ? tint.foregroundColor : tint.foregroundColor.opacity(0.35))
                .background(isEnabled ? (configuration.isPressed ? tint.backgroundColor.opacity(0.7) : tint.backgroundColor) : tint.backgroundColor.opacity(0.5))
                .clipShape(Capsule())
        }
    }
}

private extension ButtonStyleTint {
    var backgroundColor: Color {
        switch (self) {
        case .dark: return Color.black
        case .light: return Color.white
        case .gray95: return Color.Censo.gray95
        }
    }
    
    var foregroundColor: Color {
        switch (self) {
        case .dark: return Color.white
        case .light, .gray95: return Color.black
        }
    }
}
