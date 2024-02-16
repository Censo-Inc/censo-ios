//
//  BeneficiaryWelcomeBack.swift
//  Censo
//
//  Created by Brendan Flood on 2/7/24.
//

import SwiftUI

struct BeneficiaryWelcomeBack: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var ownerState: API.OwnerState.Beneficiary
    
    @State private var submitting = false
    @State private var showingError = false
    @State private var error: Error?
    
    @State private var showSettings = false
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Spacer()
            Text("Welcome back to Censo")
                .font(.largeTitle)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical)
            
            Text("""
                You are the beneficiary for someone using Censo to secure their seed phrases.

                Using the button below, you can initiate the takeover process, which, once completed, will give you access to their crypto seed phrases, as well as any instructions they may have left.
                """
            )
            .font(.headline)
            .fontWeight(.regular)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical)
            
            Spacer()
            
            Button {
                initiateTakeover()
            } label: {
                Text("Initiate takeover")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .disabled(submitting)
            
            Spacer()
            
            Button {
                self.showSettings = true
            } label: {
                HStack {
                    Image("SettingsFilled").renderingMode(.template)
                    Text("Settings")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom)
        }
        .padding()
        .padding()
        .errorAlert(isPresented: $showingError, presenting: error)
        .sheet(isPresented: $showSettings, content: {
            NavigationStack {
                SettingsTab(ownerState: .beneficiary(ownerState))
                    .toolbar(content: {
                        ToolbarItem(placement: .navigationBarLeading) {
                            DismissButton(icon: .close) {
                                showSettings = false
                            }
                        }
                    })
            }
        })
    }
    
    private func initiateTakeover() {
        self.submitting = true
        ownerRepository.initiateTakeover() { result in
            self.submitting = false
            switch result {
            case .success(let response):
                ownerStateStoreController.replace(response.ownerState)
            case .failure(let error):
                self.error = error
                self.showingError = true
            }
        }
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        BeneficiaryWelcomeBack(ownerState: .sample)
    }
}
#endif
