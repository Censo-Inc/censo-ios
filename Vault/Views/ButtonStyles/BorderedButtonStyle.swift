//
//  BorderedButtonStyle.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-25.
//

import SwiftUI

struct BorderedButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        BorderedButton(configuration: configuration)
    }

    struct BorderedBackground: View {
        var body: some View {
            RoundedRectangle(cornerRadius: 4)
                .stroke(lineWidth: 1)
                .foregroundColor(.Censo.darkBlue)
        }
    }

    struct BorderedButton: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled: Bool

        var body: some View {
            configuration.label
                .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                .font(Font.callout)
                .foregroundColor(isEnabled ? Color.Censo.darkBlue : Color.Censo.darkBlue.opacity(0.5))
                .background {
                    if isEnabled {
                        if configuration.isPressed {
                            BorderedBackground().opacity(0.7)
                        } else {
                            BorderedBackground()
                        }
                    } else {
                        BorderedBackground().opacity(0.5)
                    }
                }
                .cornerRadius(4)
        }
    }
}
