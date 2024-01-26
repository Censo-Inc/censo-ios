//
//  SubscriptionDecline.swift
//  Censo
//
//  Created by Ben Holzman on 1/25/24.
//

import SwiftUI


struct SubscriptionDecline: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.apiProvider) var apiProvider

    @Binding var ownerState: API.OwnerState
    var session: Session
    @State private var showKeep1Phrase = false
    @State private var deleteAll = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        BiometryGatedScreen(session: session, ownerState: $ownerState, onUnlockExpired: { dismiss() }) {
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
                    case .initial:
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
                    Keep1Phrase(ownerState: $ownerState, session: session)
                }
                .deleteAllDataAlert(
                    title: "Delete Data Confirmation",
                    numSeedPhrases: numSeedPhrases(),
                    deleteRequested: $deleteAll,
                    onDelete: {
                        deleteOwner(
                            apiProvider: apiProvider,
                            session: session,
                            ownerState: ownerState,
                            onSuccess: {},
                            onFailure: { error in
                                self.showingError = true
                                self.error = error
                            }
                        )
                    }
                )
                .alert("Error", isPresented: $showingError, presenting: error) { _ in
                    Button {
                        showingError = false
                        error = nil
                    } label: {
                        Text("OK")
                    }
                } message: { error in
                    Text("There was an error deleting your data.\n\(error.localizedDescription)")
                }
            }
        }
    }
    
    private func numSeedPhrases() -> Int {
        return switch ownerState {
        case .initial:
            0
        case .ready(let ready):
            ready.vault.seedPhrases.count
        }
    }
}

#if DEBUG
#Preview {
    SubscriptionDecline(ownerState: .constant(API.OwnerState.ready(API.OwnerState.Ready(policy: .sample, vault: .sample, unlockedForSeconds: UnlockedDuration(value: 600), authType: .facetec, subscriptionStatus: .none, timelockSetting: .sample, subscriptionRequired: true, onboarded: true))), session: .sample)
}
#endif
