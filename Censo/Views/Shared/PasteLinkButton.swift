//
//  PasteLinkButton.swift
//  Approver
//
//  Created by Anton Onyshchenko on 07.11.23.
//

import Foundation
import SwiftUI
import Sentry

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
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(RoundedButtonStyle())
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button("OK", role: .cancel, action: {
                self.error = nil
                self.showingError = false
            })
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    private func handlePastedInfo() {
        guard let pastedInfo = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: pastedInfo) else {
            let err = CensoError.invalidUrl(url: UIPasteboard.general.string ?? "")
            SentrySDK.captureWithTag(error: err, tagValue: "Paste Link Error")

            showError(err)
            return
        }
        onUrlPasted(url)
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
}
