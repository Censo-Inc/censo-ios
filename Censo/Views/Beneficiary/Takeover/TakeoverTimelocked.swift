//
//  TakeoverTimelocked.swift
//  Censo
//
//  Created by Brendan Flood on 2/12/24.
//

import SwiftUI

struct TakeoverTimelocked: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var takeover: API.OwnerState.Beneficiary.Phase.TakeoverTimelocked
    
    @State private var showingError = false
    @State private var error: Error?
    @State var timeRemaining: String = ""
    @State private var showingCancelConfirmation = false
    
    @State var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack {
                    
                    Text("""
            The takeover initiation was approved by \(takeover.approverContactInfo.label). Unless it is canceled, the takeover will be ready to complete in **\(timeRemaining)**.

            When the timelock period ends, \(takeover.approverContactInfo.label) will have to verify you and then the takeover will be complete.

            This verification should preferably take place either on the phone or in-person.
            """
                    )
                    .font(.headline)
                    .fontWeight(.regular)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding([.top, .horizontal])
                    
                    Spacer()
                    
                    Button {
                        showingCancelConfirmation = true
                    } label: {
                        Group {
                            Text("Cancel takeover")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .padding(.bottom)
                    
                }
            }
            .padding()
            .navigationInlineTitle("Takeover timelock")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    DismissButton(icon: .close) {
                        showingCancelConfirmation = true
                    }
                }
            })
            .cancelTakeoverWithConfirmation(isPresented: $showingCancelConfirmation, onError: showError)
            .errorAlert(isPresented: $showingError, presenting: error)
            .onAppear {
                timeRemaining = takeover.unlocksAt.toDisplayDurationWithDays()
            }
            .onReceive(timer) { time in
                if (Date.now >= takeover.unlocksAt) {
                    ownerStateStoreController.reload()
                } else {
                    timeRemaining = takeover.unlocksAt.toDisplayDurationWithDays()
                }
            }
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
        TakeoverTimelocked(takeover: .sample)
    }
}
#endif
