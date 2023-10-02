//
//  BackButton.swift
//  Vault
//
//  Created by Anton Onyshchenko on 29.09.23.
//

import Foundation
import SwiftUI

struct BackButton : View {
    var dismiss: DismissAction
    
    init(_ dismiss: DismissAction) {
        self.dismiss = dismiss
    }
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .foregroundColor(.white)
                .font(.body.bold())
        }
    }
}
