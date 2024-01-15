//
//  LoginIdResetCollectTokensStep.swift
//  Censo
//
//  Created by Anton Onyshchenko on 10.01.24.
//

import Foundation
import SwiftUI

struct LoginIdResetCollectTokensStep: View {
    var enabled: Bool
    @Binding var tokens: Set<LoginIdResetToken>
    
    @State private var showingError = false
    @State private var currentError: Error?
    
    var body: some View {
        LoginIdResetStepView(
            icon: {
                Image("Import")
                    .renderingMode(.template)
                    .resizable()
                    .padding(2)
                    .frame(width: 64, height: 64)
                    .foregroundColor(.Censo.darkBlue)
            },
            content: {
                Text("1. Collect Reset Links")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.bottom)
                
                Text("Request reset links from your approvers. Once received, tap each link to proceed, or copy and paste them using the \"Paste From Clipboard\" button.")
                    .font(.body)
                    .fontWeight(.regular)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom)
                
                VStack(alignment: .center) {
                    PasteLinkButton(onUrlPasted: onUrlPasted)
                        .padding(.horizontal)
                        .disabled(!enabled)
                        .onOpenURL(perform: {
                            if enabled {
                                onUrlPasted($0)
                            }
                        })
                    
                    if !tokens.isEmpty {
                        Text("Collected \(tokens.count) of 2 links")
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        )
        .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
            Button("OK", role: .cancel, action: {
                currentError = nil
            })
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    private func showError(_ error: Error) {
        self.currentError = error
        self.showingError = true
    }
    
    private func onUrlPasted(_ url: URL) {
        if tokens.count < 2 {
            do {
                tokens.insert(try LoginIdResetToken.fromURL(url))
            } catch {
                showError(error)
            }
        }
    }
}

