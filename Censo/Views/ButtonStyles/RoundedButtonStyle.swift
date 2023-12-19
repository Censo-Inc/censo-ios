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
                .foregroundColor(isEnabled ? tint.foregroundColor : tint.foregroundColorDisabled)
                .background(isEnabled ? (configuration.isPressed ? tint.backgroundColor.opacity(0.7) : tint.backgroundColor) : tint.backgroundColor.opacity(0.5))
                .clipShape(Capsule())
        }
    }
}

private extension ButtonStyleTint {
    var backgroundColor: Color {
        switch (self) {
        case .dark: return Color.Censo.buttonBackgroundColor
        case .light: return Color.Censo.buttonTextColor
        }
    }
    
    var foregroundColor: Color {
        switch (self) {
        case .dark: return Color.Censo.buttonTextColor
        case .light: return Color.Censo.buttonBackgroundColor
        }
    }
    
    var foregroundColorDisabled: Color {
        switch (self) {
        case .dark: return Color.white
        case .light: return Color.Censo.buttonBackgroundColor.opacity(0.35)
        }
    }
}
