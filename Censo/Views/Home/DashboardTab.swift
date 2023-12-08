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
    @Binding var parentTabViewSelectedTab: HomeScreen.TabId
    
    var body: some View {
        let vault = ownerState.vault
        let policy = ownerState.policy
        
        VStack {
            VStack {
                Spacer()
                Button {
                    parentTabViewSelectedTab = .phrases
                } label: {
                    HStack(alignment: .lastTextBaseline) {
                        Text("You have")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        Text("\(vault.seedPhrases.count)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("seed phrase\(vault.seedPhrases.count == 1 ? "" : "s").")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
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
                        .frame(maxWidth: 322, maxHeight: 4)
                }
                .padding([.top], 10)
                .buttonStyle(RoundedButtonStyle())
                
                if (policy.externalApproversCount == 0) {
                    Text("\nYou can increase security by adding approvers.")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    Button {
                        self.parentTabViewSelectedTab = HomeScreen.TabId.approvers
                    } label: {
                        Text("Add approvers")
                            .font(.headline)
                            .fontWeight(.regular)
                            .frame(maxWidth: 322, maxHeight: 4)
                    }
                    .padding([.top], 10)
                    .buttonStyle(RoundedButtonStyle())
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
    }
}
#endif
