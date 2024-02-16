//
//  LoginIdResetStartVerificationStep.swift
//  Censo
//
//  Created by Anton Onyshchenko on 10.01.24.
//

import Foundation
import SwiftUI
import Moya

struct LoginIdResetStartVerificationStep: View {
    var enabled: Bool
    var ownerRepository: OwnerRepository?
    @Binding var tokens: Set<LoginIdResetToken>
    var onDeviceCreated: () -> Void
    
    @State private var creatingDevice: Bool = false
    @State private var showingError = false
    @State private var currentError: Error?
    
    var body: some View {
        LoginIdResetStepView(
            icon: {
                Image("FaceScan")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .foregroundColor(.Censo.darkBlue)
            },
            content: {
                Text("3. Identity Verification")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.bottom)
                
                Text("For your security, we'll verify your identity. Please follow the on-screen instructions to complete this step. This ensures that only you can make the change.")
                    .font(.body)
                    .fontWeight(.regular)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom)
                
                Button(action: createDevice, label: {
                    Text("Start verification")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal)
                .disabled(!enabled || ownerRepository == nil || creatingDevice)
            }
        )
        .errorAlert(isPresented: $showingError, presenting: currentError) {
            creatingDevice = false
        }
    }
    
    private func createDevice() {
        guard let ownerRepository = ownerRepository else {
            return
        }
        creatingDevice = true
        
        ownerRepository.createDevice({ result in
            switch result {
            case .success:
                creatingDevice = false
                onDeviceCreated()
            case .failure(let error):
                showError(error)
            }
        })
    }
    
    private func showError(_ error: Error) {
        self.currentError = error
        self.showingError = true
    }
}

