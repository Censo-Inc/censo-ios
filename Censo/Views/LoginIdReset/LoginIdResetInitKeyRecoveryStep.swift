//
//  LoginIdResetInitKeyRecoveryStep.swift
//  Censo
//
//  Created by Anton Onyshchenko on 10.01.24.
//

import Foundation
import SwiftUI
import Moya

struct LoginIdResetInitKeyRecoveryStep : View {
    var enabled: Bool
    var loggedIn: Bool
    var onButtonPressed: () -> Void
    
    @State private var inProgress: Bool = false
    @State private var showingError = false
    @State private var currentError: Error?
    
    var body: some View {
        LoginIdResetStepView(
            isLast: true,
            icon: {
                Image("TwoPeople")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .foregroundColor(.Censo.darkBlue)
                    .padding(8)
            },
            content: {
                Text("4. Key Recovery")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.bottom)
                
                Text("\(loggedIn ? "Now that your Apple ID has been updated," : "Once your Apple ID is updated,") your key will need to be recovered. Assistance of both approvers is required to restore access to your seed phrases.")
                    .font(.body)
                    .fontWeight(.regular)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom)
                
                Button {
                    onButtonPressed()
                } label: {
                    Text("Recover my key")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal)
                .disabled(!enabled || inProgress)
            }
        )
        .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
            Button("OK", role: .cancel, action: {
                showingError = false
                currentError = nil
                inProgress = false
            })
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    private func showError(_ error: Error) {
        self.currentError = error
        self.showingError = true
    }
}

