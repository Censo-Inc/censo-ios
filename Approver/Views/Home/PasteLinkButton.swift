//
//  PasteLinkButton.swift
//  Approver
//
//  Created by Anton Onyshchenko on 07.11.23.
//

import Foundation
import SwiftUI
import raygun4apple

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
            let err = CensoError.invalidUrl(url: UIPasteboard.general.string ?? "")
            RaygunClient.sharedInstance().send(error: err, tags: ["Approver Paste"], customData: nil)

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
