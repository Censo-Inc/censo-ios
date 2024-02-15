//
//  InvalidLinkView.swift
//  Approver
//
//  Created by Anton Onyshchenko on 26.01.24.
//

import Foundation
import SwiftUI

struct InvalidLinkView : View {
    var body: some View {
        VStack {
            Text("Invalid link")
        }
        .multilineTextAlignment(.center)
        .navigationInlineTitle("")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                DismissButton(icon: .close)
            }
        }
    }
}
