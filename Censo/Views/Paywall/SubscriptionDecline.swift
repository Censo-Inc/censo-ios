//
//  SubscriptionDecline.swift
//  Censo
//
//  Created by Ben Holzman on 1/25/24.
//

import SwiftUI

struct SubscriptionDecline: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var ownerRepository: OwnerRepository

    var ownerState: API.OwnerState
    @State private var showKeep1Phrase = false
    @State private var deleteAll = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        BiometryGatedScreen(ownerState: ownerState, onUnlockExpired: { dismiss() }) {
            NavigationStack {
                VStack(alignment: .leading) {
                    Text("Don't want to renew your subscription?")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("Here are your options:")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    
                    switch ownerState {
                    case .ready:
                        Button {
                            showKeep1Phrase = true
                        } label: {
                            Text("Keep 1 phrase for free")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RoundedButtonStyle())
                        .padding()
                    case .initial,
                         .beneficiary:
                        EmptyView()
                    }

                    Button {
                        deleteAll = true
                    } label: {
                        Text("Delete all my data")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .padding()

                    Spacer()
                }
                .padding(20)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                })
                .navigationDestination(isPresented: $showKeep1Phrase) {
                    Keep1Phrase(ownerState: ownerState)
                }
                .deleteAllDataAlert(
                    title: "Delete Data Confirmation",
                    ownerState: ownerState,
                    deleteRequested: $deleteAll,
                    onDelete: {
                        deleteOwner(
                            ownerRepository,
                            ownerState,
                            onSuccess: {},
                            onFailure: { error in
                                self.showingError = true
                                self.error = error
                            }
                        )
                    }
                )
                .errorAlert(isPresented: $showingError, presenting: error)
            }
        }
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        SubscriptionDecline(
            ownerState: .ready(API.OwnerState.Ready(
                policy: .sample,
                vault: .sample,
                unlockedForSeconds: UnlockedDuration(value: 600),
                authType: .facetec,
                subscriptionStatus: .none,
                timelockSetting: .sample,
                subscriptionRequired: true,
                onboarded: true,
                canRequestAuthenticationReset: false
            ))
        )
    }
}
#endif
