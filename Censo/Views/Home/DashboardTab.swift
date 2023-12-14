//
//  DashboardTab.swift
//
//  Created by Brendan Flood on 10/23/23.
//

import SwiftUI

struct DashboardTab: View {
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var showingAddPhrase = false
    @State private var showingApproversSetup = false
    @Binding var parentTabViewSelectedTab: HomeScreen.TabId
    
    var body: some View {
        let vault = ownerState.vault
        let policy = ownerState.policy
        
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
                        Text("\(vault.seedPhrases.count)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("seed phrase\(vault.seedPhrases.count == 1 ? "" : "s").")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                Text("\(vault.seedPhrases.count == 1 ? "It is" : "They are") stored securely and accessible **only** to you.")
                    .font(.title3)
                    .padding()
                    .multilineTextAlignment(.center)
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
                
                if (policy.externalApproversCount == 0) {
                    Text("\nYou can increase security by adding approvers.")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    Button {
                        self.showingApproversSetup = true
                    } label: {
                        Text("Add approvers")
                            .font(.headline)
                            .fontWeight(.regular)
                            .frame(maxWidth: 322, minHeight: 24)
                    }
                    .padding([.top], 10)
                    .buttonStyle(RoundedButtonStyle())
                } else {
                    Text("\nYour security is increased by your approvers.")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 30) {
                        let approvers = ownerState.policy.approvers
                            .filter({ !$0.isOwner })
                            .sorted(using: KeyPathComparator(\.attributes.onboardedAt))

                        ForEach(Array(approvers.enumerated()), id: \.offset) { i, approver in
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
            AdditionalPhrase(
                ownerState: ownerState,
                session: session,
                onComplete: onOwnerStateUpdated
            )
        })
        .sheet(isPresented: $showingApproversSetup, content: {
            NavigationView {
                ApproversSetup(
                    session: session,
                    ownerState: ownerState,
                    onOwnerStateUpdated: onOwnerStateUpdated
                )
            }
        })
    }
}

public extension UIFont {
    static func textStyleSize(_ style: UIFont.TextStyle) -> CGFloat {
        UIFont.preferredFont(forTextStyle: style).pointSize
    }
}

#if DEBUG
#Preview {
    VStack {
        @State var selectedTab = HomeScreen.TabId.dashboard
        DashboardTab(
            session: .sample,
            ownerState: API.OwnerState.Ready(
                policy: .sample,
                vault: .sample,
                authType: .facetec,
                subscriptionStatus: .active
            ),
            onOwnerStateUpdated: { _ in },
            parentTabViewSelectedTab: $selectedTab
        )
        .foregroundColor(Color.Censo.primaryForeground)
    }
}

#Preview {
    VStack {
        @State var selectedTab = HomeScreen.TabId.dashboard
        DashboardTab(
            session: .sample,
            ownerState: API.OwnerState.Ready(
                policy: .sample2Approvers,
                vault: .sample,
                authType: .facetec,
                subscriptionStatus: .active
            ),
            onOwnerStateUpdated: { _ in },
            parentTabViewSelectedTab: $selectedTab
        )
        .foregroundColor(Color.Censo.primaryForeground)
    }
}
#endif
