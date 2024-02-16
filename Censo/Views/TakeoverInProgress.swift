//
//  TakeoverInProgress.swift
//  Censo
//
//  Created by Brendan Flood on 2/13/24.
//

import SwiftUI

struct TakeoverInProgress: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var beneficiary: API.Policy.Beneficiary
    var takeover: API.Policy.Beneficiary.Status.TakeoverInProgress
    
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        VStack(alignment: .leading) {
                
            Spacer()
            
            Text("Takeover in progress")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            
            Text("""
    Your beneficiary has initiated a takeover of your account. The takeover will be ready to complete in **\(takeover.unlocksAt?.toDisplayDurationWithDays() ?? "7 days")**. You can cancel the takeover by tapping the button below.
    """
            )
            .font(.headline)
            .fontWeight(.regular)
            .fixedSize(horizontal: false, vertical: true)
            .padding()
            
            Spacer()
            
            Button {
                cancelTakeover(ownerRepository, ownerStateStoreController, showError)
            } label: {
                Text("Cancel takeover")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding()
        }
        .padding()
        .errorAlert(isPresented: $showingError, presenting: error)
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        TakeoverInProgress(
            beneficiary: .sample,
            takeover: API.Policy.Beneficiary.Status.TakeoverInProgress(
                guid: "guid",
                createdAt: Date.now,
                unlocksAt: Date.now.addingTimeInterval(TimeInterval(500000))
            )
        )
    }
}
#endif
