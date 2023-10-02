//
//  FilledButtonStyle.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI

struct FilledButtonStyle: ButtonStyle {
    var backgroundColor: Color = Color.Censo.darkBlue
    var foregroundColor: Color = Color.white
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        FilledButton(configuration: configuration, backgroundColor: backgroundColor, foregroundColor: foregroundColor)
    }

    struct FilledButton: View {
        let configuration: ButtonStyle.Configuration
        var backgroundColor: Color
        var foregroundColor: Color
        
        @Environment(\.isEnabled) private var isEnabled: Bool

        var body: some View {
            configuration.label
                .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                .frame(maxWidth: .infinity, minHeight: 44)
                .frame(height: 55)
                .font(Font.body.bold())
                .foregroundColor(isEnabled ? foregroundColor : foregroundColor.opacity(0.35))
                .background(isEnabled ? (configuration.isPressed ? backgroundColor.opacity(0.7) : backgroundColor) : backgroundColor.opacity(0.5))
                .cornerRadius(4)
        }
    }
}
