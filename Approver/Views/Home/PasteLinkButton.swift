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
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(RoundedButtonStyle())
    }
    
    private func handlePastedInfo() {
        guard let pastedInfo = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: pastedInfo) else {
            let err = CensoError.invalidUrl(url: UIPasteboard.general.string ?? "")
            SentrySDK.captureWithTag(error: err, tagValue: "Approver Paste")

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
