//
//  RoundedButtonStyle.swift
//  Vault
//
//  Created by Ben Holzman on 10/10/23.
//

import SwiftUI

struct RoundedButtonStyle: ButtonStyle {
    var tint = ButtonStyleTint.dark
    var maxWidth: CGFloat = 322
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        RoundedButton(configuration: configuration, tint: tint, maxWidth: maxWidth)
    }

    struct RoundedButton: View {
        let configuration: ButtonStyle.Configuration
        var tint: ButtonStyleTint
        var maxWidth: CGFloat
        
        @Environment(\.isEnabled) private var isEnabled: Bool

        var body: some View {
            configuration.label
                .frame(maxWidth: maxWidth, maxHeight: 64)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(isEnabled ? tint.foregroundColor : tint.foregroundColor.opacity(0.35))
                .background(isEnabled ? (configuration.isPressed ? tint.backgroundColor.opacity(0.7) : tint.backgroundColor) : tint.backgroundColor.opacity(0.5))
                .cornerRadius(100.0)
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
