//
//  FilledButtonStyle.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI

struct FilledButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        FilledButton(configuration: configuration)
    }

    struct FilledButton: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled: Bool

        var body: some View {
            configuration.label
                .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                .frame(maxWidth: .infinity, minHeight: 44)
                .frame(height: 55)
                .font(Font.body.bold())
                .foregroundColor(isEnabled ? Color.white : Color.white.opacity(0.35))
                .background(isEnabled ? (configuration.isPressed ? Color.Censo.darkBlue.opacity(0.7) : Color.Censo.darkBlue) : Color.Censo.darkBlue.opacity(0.5))
                .cornerRadius(4)
        }
    }
}
