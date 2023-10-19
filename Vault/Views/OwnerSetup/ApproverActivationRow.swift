//
//  ApproverActivationRow.swift
//  Vault
//
//  Created by Brendan Flood on 9/5/23.
//

import SwiftUI
import Moya

struct ApproverActivationRow: View {
    @Environment(\.apiProvider) private var apiProvider

    var session: Session
    var prospectGuardian: API.ProspectGuardian
    var onOwnerStateUpdate: (API.OwnerState) -> Void

    private var participantId: ParticipantId {
        prospectGuardian.participantId
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Text("Status: ")

                    Group {
                        switch prospectGuardian.status {
                        case .declined:
                            Text("Declined")
                                .foregroundColor(.red)
                        case .initial:
                            Text("Pending")
                                .foregroundColor(.Censo.gray)
                        case .accepted, .verificationSubmitted:
                            Text("Awaiting Code")
                                .foregroundColor(.Censo.gray)
                        case .confirmed:
                            Text("Confirmed")
                                .foregroundColor(.Censo.green)
                        case .implicitlyOwner:
                            Text("Yourself!")
                                .foregroundColor(.Censo.gray) // Not sure what to do here
                        }
                    }
                    .bold()
                }
                .foregroundColor(.gray)
                .font(.callout)

                Text(prospectGuardian.label)
                    .font(.title2.weight(.heavy))
            }

            Spacer()

            switch prospectGuardian.status {
            case .initial(let initial):
                ShareLink(
                    item: initial.invitationId.url,
                    subject: Text("Censo Invitation Link for \(prospectGuardian.label)"),
                    message: Text("Censo Invitation Link for \(prospectGuardian.label)")
                ) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(4)
                        .foregroundColor(.Censo.darkBlue)
                }
            case .declined:
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(5)
                    .foregroundColor(.red)
            case .accepted(let accepted):
                RotatingTotpPinView(session: session, deviceEncryptedTotpSecret: accepted.deviceEncryptedTotpSecret
                )
            case .verificationSubmitted(let verificationSubmitted):
                ProgressView()
                    .padding(4)
                    .onAppear {
                        confirmGuardianship(status: verificationSubmitted)
                    }
            case .confirmed:
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(5)
                    .foregroundColor(.Censo.green)
            case .implicitlyOwner:
                Text("Implicit Owner") // Not sure how to proceed here
            }
        }
        .padding()
        .frame(height: 75)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.Censo.darkBlue, lineWidth: 1)
        }
        .padding(.horizontal)
    }

    private func rejectGuardianVerification(participantId: ParticipantId) {
        apiProvider.decodableRequest(
            with: session,
            endpoint: .rejectGuardianVerification(participantId)
        ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onOwnerStateUpdate(response.ownerState)
                case .failure:
                    rejectGuardianVerification(participantId: participantId) // keep trying
                }
            }
    }

    private func confirmGuardianship(status: API.GuardianStatus.VerificationSubmitted) {

        var confirmationSucceeded = false
        do {
            confirmationSucceeded = try verifyGuardianSignature(participantId: participantId, status: status)
        } catch {
            confirmationSucceeded = false
        }

        if confirmationSucceeded {
            let timeMillis = UInt64(Date().timeIntervalSince1970 * 1000)
            guard let participantIdData = participantId.value.data(using: .hexadecimal),
                  let timeMillisData = String(timeMillis).data(using: .utf8),
                  let signature = try? session.deviceKey.signature(for: status.guardianPublicKey.data + participantIdData + timeMillisData) else {
                confirmationSucceeded = false
                return
            }
            apiProvider.decodableRequest(
                with: session,
                endpoint: .confirmGuardian(
                    API.ConfirmGuardianApiRequest(
                        participantId: participantId,
                        keyConfirmationSignature: Base64EncodedString(data: signature),
                        keyConfirmationTimeMillis: timeMillis
                    )
                )
            ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onOwnerStateUpdate(response.ownerState)
                case .failure:
                    confirmGuardianship(status: status) // keep trying
                }
            }
        } else {
            rejectGuardianVerification(participantId: participantId)
        }
    }

    private func verifyGuardianSignature(participantId: ParticipantId, status: API.GuardianStatus.VerificationSubmitted) throws -> Bool {
        guard let totpSecret = try? session.deviceKey.decrypt(data: status.deviceEncryptedTotpSecret.data),
              let timeMillisBytes = String(status.timeMillis).data(using: .utf8),
              let publicKey = try? EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: status.guardianPublicKey) else {
            return false
        }

        let acceptedDate = Date(timeIntervalSince1970: Double(status.timeMillis) / 1000.0)
        for date in [acceptedDate, acceptedDate - TotpUtils.period, acceptedDate + TotpUtils.period] {
            if let codeBytes = TotpUtils.getOTP(date: date, secret: totpSecret).data(using: .utf8) {
                if try publicKey.verifySignature(for: codeBytes + timeMillisBytes, signature: status.signature) {
                    return true
                }
            }
        }

        return false
    }
}

#if DEBUG
struct ApproverActivationRow_Previews: PreviewProvider {
    static var previews: some View {
        OpenVault {
            ApproverActivationRow(session: .sample, prospectGuardian: .sample) { _ in

            }
        }
    }
}
#endif
