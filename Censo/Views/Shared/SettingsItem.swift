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
    var description: String
    var onSelected: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.title2)
                Spacer()
                Button {
                    onSelected()
                } label: {
                    Text(buttonText)
                        .font(.body.bold())
                        .padding(.horizontal)
                        .frame(minWidth: 80)
                }
                .buttonStyle(RoundedButtonStyle(tint: .light))
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
