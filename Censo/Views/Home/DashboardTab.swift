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
                    self.parentTabViewSelectedTab = HomeScreen.TabId.phrases
                } label: {
                    VStack {
                        Text("\(vault.secrets.count)")
                            .font(.system(size: UIFont.textStyleSize(.largeTitle) * 3, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(alignment: .center)
                        
                        Text("seed phrase\(vault.secrets.count != 1 ? "s" : "")")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(alignment: .center)
                    }
                    .frame(minWidth: 322, minHeight: 180, maxHeight: 247)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: vault.secrets.count == 0 ? [3] : []))
                            .foregroundColor(.Censo.lightGray)
                    )
                }
                
                Button {
                    showingAddPhrase = true
                } label: {
                    Text("Add seed phrase")
                        .foregroundColor(.black)
                        .font(.headline)
                        .fontWeight(.regular)
                        .frame(maxWidth: 322, maxHeight: 4)
                }
                .padding([.top], 10)
                .buttonStyle(RoundedButtonStyle(tint: .gray95))
                
                Divider().padding([.top, .bottom], 10)
                
                Button {
                    self.parentTabViewSelectedTab = HomeScreen.TabId.approvers
                } label: {
                    VStack {
                        Text("\(policy.externalApproversCount)")
                            .font(.system(size: UIFont.textStyleSize(.largeTitle) * 3, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(alignment: .center)
                        
                        Text("approver\(policy.externalApproversCount != 1 ? "s" : "")")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(alignment: .center)
                    }
                    .frame(minWidth: 322, minHeight: 180, maxHeight: 247)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: policy.externalApproversCount == 0 ? [3] : []))
                            .foregroundColor(.Censo.lightGray)
                    )
                }
                
                if policy.externalApproversCount == 0 {
                    Button {
                        self.parentTabViewSelectedTab = HomeScreen.TabId.approvers
                    } label: {
                        Text("Add approvers")
                            .foregroundColor(.black)
                            .font(.headline)
                            .fontWeight(.regular)
                            .frame(maxWidth: 322, maxHeight: 4)
                    }
                    .padding([.top], 10)
                    .buttonStyle(RoundedButtonStyle(tint: .gray95))
                }
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
                vault: .sample
            ),
            onOwnerStateUpdated: { _ in },
            parentTabViewSelectedTab: $selectedTab
        )
    }
}
#endif
