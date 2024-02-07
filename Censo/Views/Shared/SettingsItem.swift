//
//  SettingsItem.swift
//  Censo
//
//  Created by Anton Onyshchenko on 20.12.23.
//

import SwiftUI
import Moya

struct SettingsItem: View {
    var title: String
    var buttonText: String
    var buttonIdentifier: String? = nil
    var description: String
    var buttonDisabled: Bool = false
    var onSelected: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    onSelected()
                } label: {
                    Text(buttonText)
                        .font(.headline)
                        .padding(.horizontal)
                        .frame(minWidth: 80)
                }
                .buttonStyle(RoundedButtonStyle(tint: .light))
                .disabled(buttonDisabled)
                .accessibilityIdentifier(buttonIdentifier ?? "\(buttonText)Button")
            }
            
            Text(description)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
        .padding()
    }
}
