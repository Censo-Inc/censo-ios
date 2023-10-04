//
//  FilledButtonStyle.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI

struct FilledButtonStyle: ButtonStyle {
    var tint = ButtonStyleTint.dark
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        FilledButton(configuration: configuration, tint: tint)
    }

    struct FilledButton: View {
        let configuration: ButtonStyle.Configuration
        var tint: ButtonStyleTint
        
        @Environment(\.isEnabled) private var isEnabled: Bool

        var body: some View {
            configuration.label
                .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                .frame(maxWidth: .infinity, minHeight: 44)
                .frame(height: 55)
                .font(Font.body.bold())
                .foregroundColor(isEnabled ? tint.foregroundColor : tint.foregroundColor.opacity(0.35))
                .background(isEnabled ? (configuration.isPressed ? tint.backgroundColor.opacity(0.7) : tint.backgroundColor) : tint.backgroundColor.opacity(0.5))
                .cornerRadius(4)
        }
    }
}

private extension ButtonStyleTint {
    var backgroundColor: Color {
        switch (self) {
        case .dark: return Color.Censo.darkBlue
        case .light: return Color.white
        }
    }
    
    var foregroundColor: Color {
        switch (self) {
        case .dark: return Color.white
        case .light: return Color.Censo.darkBlue
        }
    }
}
