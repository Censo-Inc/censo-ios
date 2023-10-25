//
//  RoundedTextFieldStyle.swift
//  Vault
//
//  Created by Anton Onyshchenko on 19.10.23.
//

import Foundation
import SwiftUI

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding()
            .multilineTextAlignment(.center)
            .overlay(
                RoundedRectangle(cornerRadius: 100.0)
                    .strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0))
            )
    }
}
