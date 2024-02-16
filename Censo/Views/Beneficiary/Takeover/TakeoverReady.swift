//
//  TakeoverReady.swift
//  Censo
//
//  Created by Brendan Flood on 2/13/24.
//

import SwiftUI
import Sentry

struct TakeoverReady: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var beneficiary: API.OwnerState.Beneficiary
    var onCancel: () -> Void
    
    enum Step {
        case enterTotp
        case retrieveKey(API.OwnerState.Beneficiary.Phase.TakeoverAvailable)
        case finalize(API.OwnerState.Beneficiary.Phase.TakeoverAvailable, Base64EncodedString, API.Authentication.Password?)
        case takeoverDone(API.OwnerState)
        case promptForPush(API.OwnerState)
    }
    
    @State private var step: Step = .enterTotp
    @State private var showingCancelConfirmation = false
    @State private var showingError = false
    @State private var error: Error?
    
    @AppStorage("pushNotificationsEnabled") var pushNotificationsEnabled: String?
    
    var body: some View {
        
        switch(step) {
        case .enterTotp:
            NavigationStack {
                EnterTakeoverVerificationCode(
                    beneficiary: beneficiary,
                    onSuccess: { takeoverAvailable in
                        step = .retrieveKey(takeoverAvailable)
                    }
                )
                .navigationInlineTitle("Takeover ready")
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        DismissButton(icon: .close) {
                            showingCancelConfirmation = true
                        }
                    }
                })
                .cancelTakeoverWithConfirmation(isPresented: $showingCancelConfirmation, onError: showError)
            }
        case .retrieveKey(let takeover):
            RetrieveTakeoverKey(
                authType: beneficiary.authType,
                onSuccess: { encryptedKey, password in
                    step = .finalize(takeover, encryptedKey, password)
                }, 
                onCancelled: {
                    step = .enterTotp
                }
            )
        case .finalize(let takeoverAvailable, let encryptedKey, let password):
            ProgressView("Finalizing takeover")
                .onAppear {
                    finalizeTakeover(
                        takeover: takeoverAvailable,
                        doubleEncryptedKey: encryptedKey,
                        password: password
                    )
                }
                .errorAlert(isPresented: $showingError, presenting: error) {
                    step = .enterTotp
                }
        case .takeoverDone(let ownerState):
            TakeoverComplete()
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if pushNotificationsEnabled != "true" {
                            step = .promptForPush(ownerState)
                        } else {
                            ownerStateStoreController.replace(ownerState)
                        }
                    }
                })
        case .promptForPush(let ownerState):
            NavigationStack {
                PushNotificationSettings {
                    ownerStateStoreController.replace(ownerState)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        DismissButton(icon: .close) {
                            ownerStateStoreController.replace(ownerState)
                        }
                    }
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
    
    private func finalizeTakeover(takeover: API.OwnerState.Beneficiary.Phase.TakeoverAvailable,
                                  doubleEncryptedKey: Base64EncodedString,
                                  password: API.Authentication.Password?) {
        do {
            try ownerRepository.finalizeTakeover(
                beneficiary: self.beneficiary,
                takeover: takeover,
                doubleEncryptedKey: doubleEncryptedKey,
                password: password
            ) { result in
                switch result {
                case .success(let response):
                    step = .takeoverDone(response.ownerState)
                case .failure(let error):
                    self.error = error
                }
            }
         } catch {
             SentrySDK.captureWithTag(error: error, tagValue: "finalizeTakeover")
             showError(error)
        }
    }
}

struct TakeoverComplete: View {
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Text("Takeover\nComplete")
                .font(.largeTitle)
            Spacer()
        }
    
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        TakeoverReady(
            beneficiary: .sampleTakeoverVerificationPending,
            onCancel: {}
        )
    }
}

#Preview("Complete") {
    LoggedInOwnerPreviewContainer {
        TakeoverComplete()
    }
}
#endif
