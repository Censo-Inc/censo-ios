//
//  EnterTakeoverVerificationCode.swift
//  Censo
//
//  Created by Brendan Flood on 2/13/24.
//

import SwiftUI
import Sentry

struct EnterTakeoverVerificationCode: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var beneficiary: API.OwnerState.Beneficiary
    var onSuccess: (API.OwnerState.Beneficiary.Phase.TakeoverAvailable) -> Void
    
    @State private var verificationCode: [Int] = []
    @State private var submitting = false
    @State private var showingError = false
    @State private var error: Error?
    
    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            Text("\(beneficiary.phase.approverContact.label) will need to verify you. This verification should preferably take place either on the phone or in-person.")
                .font(.subheadline)
                .fontWeight(.regular)
                .padding(.vertical)
            
            VStack(spacing: 0) {
                let sharelinkDisabled = beneficiary.phase.waitingForSignature || beneficiary.phase.isTakeoverAvailable
                HStack(alignment: .top, spacing: 20) {
                    VStack {
                        Image("CensoLogoDarkBlueStacked")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .padding()
                            .clipShape(RoundedRectangle(cornerRadius: 16.0))
                            .foregroundColor(.Censo.aquaBlue)
                            .background(
                                RoundedRectangle(cornerRadius: 16.0)
                            )
                        
                        Rectangle()
                            .fill(Color.Censo.darkBlue)
                            .frame(minHeight: 40)
                            .frame(maxWidth: 3, maxHeight: 80)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Step 1: Share this link")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Share this link and have \(beneficiary.phase.approverContact.label) click it or paste into their Approver app.")
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 4)
                        
                        if let link = URL(string: "\(Configuration.approverUrlScheme)://takeover-verification/v1/\(beneficiary.phase.approverContact.participantId.value)/\(beneficiary.phase.takeoverId)") {
                            ShareLink(
                                item: link
                            ) {
                                HStack(spacing: 0) {
                                    Image("Export")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 6)
                                        .foregroundColor(sharelinkDisabled ? .white : .Censo.buttonTextColor)
                                        .bold()
                                    Text("Share")
                                        .font(.headline)
                                        .foregroundColor(sharelinkDisabled ? .white : .Censo.buttonTextColor)
                                        .padding(.trailing)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 20.0)
                                        .fill(sharelinkDisabled ? Color.Censo.buttonBackgroundColor.opacity(0.5) : Color.Censo.buttonBackgroundColor)
                                        .frame(width: 128)
                                        
                                )
                            }
                            .padding(.leading)
                            .padding(.bottom)
                            .disabled(sharelinkDisabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)

                HStack(alignment: .top) {
                    Image("PhoneWaveform")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .padding(.horizontal, 8)

                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Step 2: Enter the Code")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Have \(beneficiary.phase.approverContact.label) read aloud the 6-digit code from their Approver app and enter it below.")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical)
            
            VStack(spacing: 0) {
                if case .takeoverVerificationPending(_) = beneficiary.phase {
                    ProgressView("Waiting for \(beneficiary.phase.approverContact.label) to open the link")
                } else if beneficiary.phase.isTakeoverAvailable {
                    Group {
                        Spacer()
                        Text("\(beneficiary.phase.approverContact.label) has successfully verified you. Please tap the button below to continue. To complete the takeover you will need to  \(beneficiary.authType == .password ? "enter your password" : "scan your face").")
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical)
                    }
                } else {
                    if case .takeoverVerificationSignatureRejected(_) = beneficiary.phase {
                        Text(CensoError.verificationFailed.localizedDescription)
                            .bold()
                            .foregroundColor(Color.red)
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    VerificationCodeEntry(
                        pinInput: $verificationCode,
                        disabled: submitting || !beneficiary.phase.waitingForSignature
                    )
                    .onChange(of: verificationCode) { _ in
                        if (verificationCode.count == 6) {
                            submitVerificationCode(
                                verificationCode.map({ digit in String(digit) }).joined()
                            )
                        }
                    }
                }
                    
                if submitting || beneficiary.phase.waitingForVerification {
                    ProgressView(
                        "Waiting for \(beneficiary.phase.approverContact.label) to verify the code"
                    ).multilineTextAlignment(.center)
                }
            }
            Spacer()
            
            Button {
                onSuccess(beneficiary.phase.takeoverAvailable!)
            } label: {
                Group {
                    Text("Complete takeover")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(.bottom)
            .disabled(!beneficiary.phase.isTakeoverAvailable)
        }
        .padding(.vertical)
        .padding(.horizontal)
        .modifier(RefreshOnTimer(timer: $refreshStatePublisher, refresh: refreshState, isIdleTimerDisabled: true))
        .errorAlert(isPresented: $showingError, presenting: error)
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
    
    private func refreshState() {
        ownerRepository.getUser { result in
            switch result {
            case .success(let user):
                ownerStateStoreController.replace(user.ownerState)
            default:
                break
            }
        }
    }
    
    private func submitVerificationCode(_ code: String) {
        submitting = true
        self.error = nil
        do {
            try ownerRepository.submitTakeoverTotpVerification(
                code: code
            ) { result in
                switch result {
                case .success(let response):
                    ownerStateStoreController.replace(response.ownerState)
                case .failure(let error):
                    self.error = error
                }
            }
        } catch {
            SentrySDK.captureWithTag(error: CensoError.failedToCreateSignature, tagValue: "Beneficiary Verification")
            self.error = CensoError.failedToCreateSignature
        }
        self.submitting = false
    }
}

extension API.OwnerState {
    var beneficiary: API.OwnerState.Beneficiary? {
        get {
            guard case let .beneficiary(beneficiary) = self
            else { return nil }
            return beneficiary
        }
    }
}

#if DEBUG
#Preview("Pending") {
    LoggedInOwnerPreviewContainer {
        EnterTakeoverVerificationCode(
            beneficiary: .sampleTakeoverVerificationPending,
            onSuccess: {_ in}
        )
    }
}

#Preview("available") {
    LoggedInOwnerPreviewContainer {
        EnterTakeoverVerificationCode(
            beneficiary: .sampleTakeoverAvailable,
            onSuccess: {_ in}
        )
    }
}
#endif
