//
//  TakeoverRejected.swift
//  Censo
//
//  Created by Brendan Flood on 2/12/24.
//

import SwiftUI

struct TakeoverRejected: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var takeover: API.OwnerState.Beneficiary.Phase.TakeoverRejected
    
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack {
                    
                    Text("""
            The takeover initiation was rejected by \(takeover.approverContactInfo.label).

            You cannot continue with this takeover, but you can cancel and try again.
            """
                    )
                    .font(.headline)
                    .fontWeight(.regular)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding([.top, .horizontal])
                    
                    Spacer()
                    
                    Button {
                        cancelTakeover(ownerRepository, ownerStateStoreController, showError)
                    } label: {
                        Text("Cancel takeover")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .padding(.bottom)
                    
                }
            }
            .padding()
            .navigationInlineTitle("Takeover rejected")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    DismissButton(icon: .close) {
                        cancelTakeover(ownerRepository, ownerStateStoreController, showError)
                    }
                }
            })
            .errorAlert(isPresented: $showingError, presenting: error)
        }
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        TakeoverRejected(takeover: .sample)
    }
}
#endif
