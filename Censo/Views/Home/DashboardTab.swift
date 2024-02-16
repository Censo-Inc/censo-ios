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
        VStack(alignment: .center) {
            Image("Dashboard")
            Spacer()
            VStack {
                HStack(alignment: .lastTextBaseline) {
                    Text("You have")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("\(ownerState.vault.seedPhrases.count)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("seed phrase\(ownerState.vault.seedPhrases.count == 1 ? "" : "s").")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .padding()
                .frame(maxWidth: .infinity)

                Text("\(ownerState.vault.seedPhrases.count == 1 ? "It is" : "They are") stored securely and accessible **only** to you.")
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .fixedSize(horizontal: false, vertical: true)
            .clipShape(RoundedRectangle(cornerRadius: 16.0))
            .background(
                RoundedRectangle(cornerRadius: 16.0)
                    .fill(Color.Censo.aquaBlue.opacity(0.24))
                    .padding()
            )
            Spacer()
                .frame(maxHeight: 32)

            VStack(alignment: .leading) {
                if (ownerState.policy.externalApproversCount == 0) {
                    Text("\nYou can increase security by adding approvers.")
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
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
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top)
                    .buttonStyle(RoundedButtonStyle())
                    .accessibilityIdentifier("addApprovers")
                } else {
                    Text("Your Approvers")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(spacing: 30) {
                        ForEach(Array(ownerState.policy.externalApprovers.enumerated()), id: \.offset) { i, approver in
                            ApproverPill(approver: .trusted(approver))
                        }
                    }
                }
            }
            .padding()
            .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingAddPhrase, content: {
            AdditionalPhrase(ownerState: ownerState)
        })
        .sheet(isPresented: $showingApproversSetup, content: {
            NavigationView {
                ApproversSetup(ownerState: ownerState)
            }
        })
        .errorAlert(isPresented: $showingError, presenting: error)
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
