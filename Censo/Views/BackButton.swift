//
//  BackButton.swift
//  Censo
//
//  Created by Anton Onyshchenko on 29.09.23.
//

import Foundation
import SwiftUI

struct BackButton : View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .foregroundColor(.Censo.primaryForeground)
                .font(.body.bold())
        }
    }
}
