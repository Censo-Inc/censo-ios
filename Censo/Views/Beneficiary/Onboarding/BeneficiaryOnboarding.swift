//
//  BeneficiaryOnboarding.swift
//  Censo
//
//  Created by Brendan Flood on 2/7/24.
//

import SwiftUI

struct BeneficiaryOnboarding: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    @State var beneficiaryInvitationId: BeneficiaryInvitationId?
    @State private var readyToStartEnrollment: Bool = false
    
    @State private var showingError = false
    @State private var error: Error?
    
    var onCancel: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        VStack {
            if let beneficiaryInvitationId {
                AuthEnrollmentView(
                    onPasswordReady: { cryptedPassword in
                        ownerRepository.acceptBeneficiaryInviteWithPassword(
                            beneficiaryInvitationId,
                            API.AcceptBeneficiaryInvitationWithPasswordApiRequest(
                                password: API.Authentication.Password(cryptedPassword: cryptedPassword)
                            )
                        ) { result in
                            switch result {
                            case .failure:
                                dismiss()
                            case .success(let response):
                                ownerStateStoreController.replace(response.ownerState)
                            }
                        }
                    },
                    onFaceScanReady: { facetecBiometry, completion in
                        ownerRepository.acceptBeneficiaryInvite(
                            beneficiaryInvitationId,
                            API.AcceptBeneficiaryInvitationApiRequest(
                                biometryVerificationId: facetecBiometry.verificationId,
                                biometryData: facetecBiometry
                            ),
                            completion
                        )
                    },
                    onFaceScanSuccess: { ownerState in
                        ownerStateStoreController.replace(ownerState)
                    },
                    onCancel: onDelete
                    
                )
            } else {
                VStack(alignment: .leading) {
                    
                    Text("Becoming a beneficiary?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical)
                    
                    Text("""
                        If you’ve been chosen by someone using Censo to be their beneficiary, you’ve come to the right place!
                        
                        To continue, they must send you a link.
                        
                        Once you receive it, you can tap on it to continue.
                        
                        Or, simply copy the link to the clipboard and paste using the button below.
                        """
                    )
                    .font(.headline)
                    .fontWeight(.regular)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical)
                    
                    Spacer()
                    
                    PasteLinkButton {url in
                        onUrlPasted(url)
                    }
                    .padding(.bottom)
                }
                .padding()
                .padding()
                .onboardingCancelNavBar(
                    onCancel: onCancel,
                    showAsBack: true
                )
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
    
    func onUrlPasted(_ url: URL) {
        guard let invitiatonId = try? BeneficiaryInvitationId.fromURL(url) else {
            showError(ValueWrapperError.invalidInvitationId)
            return
        }
        self.beneficiaryInvitationId = invitiatonId
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        BeneficiaryOnboarding(onCancel: {}, onDelete: {})
    }
}
#endif


