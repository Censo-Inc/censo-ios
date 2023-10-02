//
//  BorderedButtonStyle.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-25.
//

import SwiftUI

struct BorderedButtonStyle: ButtonStyle {
    var foregroundColor: Color = Color.Censo.darkBlue
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        BorderedButton(configuration: configuration, foregroundColor: foregroundColor)
    }

    struct BorderedBackground: View {
        var foregroundColor: Color
        
        var body: some View {
            RoundedRectangle(cornerRadius: 4)
                .stroke(lineWidth: 1)
                .foregroundColor(foregroundColor)
        }
    }

    struct BorderedButton: View {
        let configuration: ButtonStyle.Configuration
        var foregroundColor: Color
        @Environment(\.isEnabled) private var isEnabled: Bool

        var body: some View {
            configuration.label
                .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                .font(Font.callout)
                .foregroundColor(isEnabled ? foregroundColor : foregroundColor.opacity(0.5))
                .background {
                    if isEnabled {
                        if configuration.isPressed {
                            BorderedBackground(foregroundColor: foregroundColor).opacity(0.7)
                        } else {
                            BorderedBackground(foregroundColor: foregroundColor)
                        }
                    } else {
                        BorderedBackground(foregroundColor: foregroundColor).opacity(0.5)
                    }
                }
                .cornerRadius(4)
        }
    }
}
