//
//  TakeoverInitiated.swift
//  Censo
//
//  Created by Brendan Flood on 2/12/24.
//

import SwiftUI
import Sentry

struct TakeoverInitiated: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    enum Step {
      case initial
      case decryptionFailed(Error)
      case share(approverContactMap: [ParticipantId: String])
    }
    
    var beneficiary: API.OwnerState.Beneficiary
    var takeover: API.OwnerState.Beneficiary.Phase.TakeoverInitiated
    
    @State private var showingError = false
    @State private var error: Error?
    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @State private var selectedIndex: Int = 0
    @State private var step: Step = .initial
    
    
    var body: some View {
        NavigationStack {
            switch self.step {
            case .initial:
                ProgressView()
                    .onAppear {
                        decryptApproverContactMap()
                    }
                
            case .decryptionFailed(let error):
                RetryView(error: error, action: decryptApproverContactMap)
                
            case .share(let approverContactMap):
                VStack(alignment: .leading, spacing: 0) {
                    VStack {
                        
                        Text("""
                Takeover initiation requires the approval of one of the two Trusted Approvers on the account.
                
                You will need to share a link with them, which they will need to tap on or paste into their Approver app.
                
                Select one of the approvers, and click the Share button
                """
                        )
                        .font(.headline)
                        .fontWeight(.regular)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding([.top, .horizontal])
                        
                        ApproverContacts(
                            takeover: takeover,
                            approverContactMap: approverContactMap,
                            selectedIndex: $selectedIndex
                        )
                        
                        if let link = URL(string: "\(Configuration.approverUrlScheme)://takeover-initiation/v1/\(takeover.approverContactInfo[selectedIndex].participantId.value)/\(takeover.guid)") {
                            ShareLink(
                                item: link
                            ) {
                                HStack(spacing: 0) {
                                    Image("Export")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .padding(.horizontal, 6)
                                        .foregroundColor(.Censo.aquaBlue)
                                    Text("Share")
                                        .font(.headline)
                                        .foregroundColor(.Censo.aquaBlue)
                                        .padding(.trailing)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 20.0)
                                )
                            }
                            .padding()
                        }
                        
                    }
                }
                .padding()
                .navigationInlineTitle("Takeover initiation")
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        DismissButton(icon: .close) {
                            cancelTakeover(ownerRepository, ownerStateStoreController, showError)
                        }
                    }
                })
                .errorAlert(isPresented: $showingError, presenting: error)
                .modifier(RefreshOnTimer(timer: $refreshStatePublisher, refresh: ownerStateStoreController.reload, isIdleTimerDisabled: true))
            }
        }
    }
    
    func decryptApproverContactMap() {
        do {
            let beneficiaryApproverKey = try ownerRepository.getOrCreateApproverKey(keyId: beneficiary.invitationId, entropy: beneficiary.entropy.data)
            SentrySDK.addCrumb(category: "Approver Contacts", message: "retrieved beneficiary key")
            self.step = .share(approverContactMap: try takeover.approverContactInfo.reduce(into: [ParticipantId: String]()) { result, contact in
                if let encryptedContactInfo = contact.encryptedContactInfo {
                    result[contact.participantId] = String(decoding: try beneficiaryApproverKey.decrypt(base64EncodedString: encryptedContactInfo), as: UTF8.self)
                }
            })
        } catch {
            SentrySDK.captureWithTag(error: CensoError.failedToDecryptSecrets, tagValue: "Encrypted Contacts")
            self.step = .decryptionFailed(CensoError.failedToDecryptApproverContactInfo)
        }
    }
    
    func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
}

struct ApproverContacts: View {
    var takeover: API.OwnerState.Beneficiary.Phase.TakeoverInitiated
    var approverContactMap: [ParticipantId: String]
    @Binding var selectedIndex: Int
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedIndex) {
                ForEach(Array(takeover.approverContactInfo.enumerated()), id: \.offset) { i, approverContact in
                    VStack(spacing: 0) {
                        
                        Text(approverContact.label)
                            .padding()
                            .font(.title)
                        
                        Text("Contact information:")
                            .font(.headline)
                        
                        if let contactInfo = approverContactMap[approverContact.participantId] {
                            Text(contactInfo)
                                .padding(.vertical, 5)
                                .font(.headline)
                        } else {
                            Text("None Provided")
                                .padding(.vertical, 5)
                                .font(.headline)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                            )
                    }
                    .padding(20)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
    }
}
    
#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        TakeoverInitiated(beneficiary: .sampleTakeoverInitiated,
                          takeover: .sample)
    }
}
#endif
