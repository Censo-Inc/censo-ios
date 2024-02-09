//
//  InvalidLinkView.swift
//  Approver
//
//  Created by Anton Onyshchenko on 26.01.24.
//

import Foundation
import SwiftUI

struct InvalidLinkView : View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Invalid link")
        }
        .multilineTextAlignment(.center)
        .navigationTitle(Text(""))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}
