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
            HStack {
                Spacer()
                Image("Clipboard")
                    .resizable()
                    .frame(width: 36, height: 36)
                Text("Paste link")
                    .font(.system(size: 24, weight: .semibold))
                    .padding(.horizontal)
                Spacer()
            }
        }
        .buttonStyle(RoundedButtonStyle())
        .frame(maxWidth: .infinity)
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
