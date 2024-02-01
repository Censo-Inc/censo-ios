//
//  DashboardTab.swift
//
//  Created by Brendan Flood on 10/23/23.
//

import SwiftUI

struct DashboardTab: View {
    var ownerState: API.OwnerState.Ready
    
    @State private var showingError = false
    @State private var error: Error?
    @State private var showingAddPhrase = false
    @State private var showingApproversSetup = false
    @Binding var parentTabViewSelectedTab: HomeScreen.TabId
    
    var body: some View {
        ScrollView {
            Spacer()
            
            VStack {
                Spacer()
                Button {
                    parentTabViewSelectedTab = .phrases
                } label: {
                    HStack(alignment: .lastTextBaseline) {
                        Text("You have")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("\(ownerState.vault.seedPhrases.count)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("seed phrase\(ownerState.vault.seedPhrases.count == 1 ? "" : "s").")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                Text("\(ownerState.vault.seedPhrases.count == 1 ? "It is" : "They are") stored securely and accessible **only** to you.")
                    .font(.title3)
                    .padding()
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    showingAddPhrase = true
                } label: {
                    Text("Add seed phrase")
                        .font(.headline)
                        .fontWeight(.regular)
                        .frame(maxWidth: 322, minHeight: 24)
                }
                .padding([.top], 10)
                .buttonStyle(RoundedButtonStyle())
                .accessibilityIdentifier("addSeedPhraseButton")

                Spacer().padding()

                if (ownerState.policy.externalApproversCount == 0) {
                    Text("\nYou can increase security by adding approvers.")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        if ownerState.hasBlockingPhraseAccessRequest {
                            self.error = CensoError.cannotSetupApproversWhileAccessInProgress
                            self.showingError = true
                        } else {
                            self.showingApproversSetup = true
                        }
                    } label: {
                        Text(ownerState.policySetup == nil ? "Add approvers" : "Resume adding approvers")
                            .font(.headline)
                            .fontWeight(.regular)
                            .frame(maxWidth: 322, minHeight: 24)
                    }
                    .padding([.top], 10)
                    .buttonStyle(RoundedButtonStyle())
                    .accessibilityIdentifier("addApprovers")
                } else {
                    Text("Your approvers:")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 30) {
                        ForEach(Array(ownerState.policy.externalApprovers.enumerated()), id: \.offset) { i, approver in
                          ApproverPill(isPrimary: i == 0, approver: .trusted(approver))
                        }
                    }
                    .padding([.top], 10)
                    .padding([.leading, .trailing], 30)
                }
                
                Spacer()
            }.frame(maxWidth: 322)
        }
        .sheet(isPresented: $showingAddPhrase, content: {
            AdditionalPhrase(ownerState: ownerState)
        })
        .sheet(isPresented: $showingApproversSetup, content: {
            NavigationView {
                ApproversSetup(ownerState: ownerState)
            }
        })
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button {
                showingError = false
                error = nil
            } label: { Text("OK") }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

public extension UIFont {
    static func textStyleSize(_ style: UIFont.TextStyle) -> CGFloat {
        UIFont.preferredFont(forTextStyle: style).pointSize
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        @State var selectedTab = HomeScreen.TabId.dashboard
        DashboardTab(
            ownerState: .sample,
            parentTabViewSelectedTab: $selectedTab
        )
    }
}

#Preview {
    LoggedInOwnerPreviewContainer {
        @State var selectedTab = HomeScreen.TabId.dashboard
        DashboardTab(
            ownerState: API.OwnerState.Ready(
                policy: .sample2Approvers,
                vault: .sample,
                authType: .facetec,
                subscriptionStatus: .active,
                timelockSetting: .sample,
                subscriptionRequired: true,
                onboarded: true,
                canRequestAuthenticationReset: false
            ),
            parentTabViewSelectedTab: $selectedTab
        )
    }
}
#endif
