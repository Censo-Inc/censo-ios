//
//  BorderedButtonStyle.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-25.
//

import SwiftUI

struct BorderedButtonStyle: ButtonStyle {
    var tint = ButtonStyleTint.dark
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        BorderedButton(configuration: configuration, tint: tint)
    }

    struct BorderedBackground: View {
        var tint: ButtonStyleTint
        
        var body: some View {
            RoundedRectangle(cornerRadius: 4)
                .stroke(lineWidth: 1)
                .foregroundColor(tint.color)
        }
    }

    struct BorderedButton: View {
        let configuration: ButtonStyle.Configuration
        var tint: ButtonStyleTint
        @Environment(\.isEnabled) private var isEnabled: Bool

        var body: some View {
            configuration.label
                .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                .font(Font.callout)
                .foregroundColor(isEnabled ? tint.color : tint.color.opacity(0.5))
                .background {
                    if isEnabled {
                        if configuration.isPressed {
                            BorderedBackground(tint: tint).opacity(0.7)
                        } else {
                            BorderedBackground(tint: tint)
                        }
                    } else {
                        BorderedBackground(tint: tint).opacity(0.5)
                    }
                }
                .cornerRadius(4)
        }
    }
}

private extension ButtonStyleTint {
    var color: Color {
        switch (self) {
        case .dark: return Color.Censo.darkBlue
        case .light: return Color.white
        }
    }
}

