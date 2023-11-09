//
//  PasteLinkButton.swift
//  Approver
//
//  Created by Anton Onyshchenko on 07.11.23.
//

import Foundation
import SwiftUI

struct PasteLinkButton: View {
    var onUrlPasted: (URL) -> Void
    
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        Button {
            handlePastedInfo()
        } label: {
            Text("Paste from clipboard")
                .font(.title3)
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(RoundedButtonStyle())
    }
    
    private func handlePastedInfo() {
        guard let pastedInfo = UIPasteboard.general.string,
              let url = URL(string: pastedInfo) else {
            showError(CensoError.invalidUrl)
            return
            
        }
        onUrlPasted(url)
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
}
