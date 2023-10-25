//
//  HomeView.swift
//  Vault
//
//  Created by Brendan Flood on 10/23/23.
//

import SwiftUI

struct HomeView: View {
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var showingAddPhrase = false
    
    var body: some View {
        let vault = ownerState.vault
        let policy = ownerState.policy
        
        VStack {
            VStack {
                Spacer()
                VStack {
                    Text("\(vault.secrets.count)")
                        .font(.system(size: 100, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(alignment: .center)
                    
                    Text("seed phrase\(vault.secrets.count != 1 ? "s" : "")")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(alignment: .center)
                }
                .frame(minWidth: 322, minHeight: 247)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: vault.secrets.count == 0 ? [3] : []))
                        .foregroundColor(.Censo.lightGray)
                )
                
                Button {
                    showingAddPhrase = true
                } label: {
                    Text("Add seed phrase")
                        .foregroundColor(.black)
                        .font(.system(size: 18, weight: .regular))
                        .frame(maxWidth: 322, maxHeight: 4)
                }
                .padding([.top], 10)
                .buttonStyle(RoundedButtonStyle(tint: .gray95))
                
                Divider().padding([.top, .bottom], 10)
                
                VStack {
                    Text("\(policy.guardians.externalApproverCount)")
                        .font(.system(size: 100, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(alignment: .center)
                    
                    Text("approver\(policy.guardians.externalApproverCount != 1 ? "s" : "")")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(alignment: .center)
                }
                .frame(minWidth: 322, minHeight: 247)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: policy.guardians.externalApproverCount == 0 ? [3] : []))
                        .foregroundColor(.Censo.lightGray)
                )
                
                if policy.guardians.externalApproverCount == 0 {
                    NavigationLink {
                        
                    } label: {
                        Text("Add approvers")
                            .foregroundColor(.black)
                            .font(.system(size: 18, weight: .regular))
                            .frame(maxWidth: 322, maxHeight: 4)
                    }
                    .padding([.top], 10)
                    .buttonStyle(RoundedButtonStyle(tint: .gray95))
                    
                }
            }.frame(maxWidth: 322)
            
            
            Divider()
            .padding([.bottom], 4)
            .frame(maxHeight: .infinity, alignment: .bottom)
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

extension Array where Element == API.TrustedGuardian {
    var externalApproverCount: Int {
      return self.count - 1
  }
}

#if DEBUG

#Preview {
    HomeView(
        session: .sample,
        ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample),
        onOwnerStateUpdated: { _ in }
    )
}
#endif
