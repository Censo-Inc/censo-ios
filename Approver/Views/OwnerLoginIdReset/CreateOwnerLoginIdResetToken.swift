//
//  CreateOwnerLoginIdResetToken.swift
//  Approver
//
//  Created by Anton Onyshchenko on 04.01.24.
//

import Foundation
import SwiftUI
import Moya

struct CreateOwnerLoginIdResetToken: View {
    @Environment(\.apiProvider) var apiProvider
    var session: Session
    var participantId: ParticipantId
    @Binding var user: API.ApproverUser
    var onSuccess: (API.OwnerLoginIdResetToken) -> Void

    @State private var status: Status = .idle

    enum Status {
        case idle
        case inProgress
        case success(API.OwnerLoginIdResetToken)
        case failed(Error)
    }

    var body: some View {
        switch (status) {
        case .idle:
            ProgressView()
                .onAppear(perform: createToken)
        case .inProgress:
            ProgressView()
        case .success(let token):
            ProgressView()
                .onAppear {
                    onSuccess(token)
                }
        case .failed(let error):
            RetryView(error: error, action: createToken)
        }
    }
    
    private func createToken() {
        status = .inProgress
        
        apiProvider.decodableRequest(
            with: session,
            endpoint: .createOwnerLoginIdResetToken(participantId)
        ) { (result: Result<API.ApproverUser, MoyaError>) in
            switch result {
            case .success(let updatedUser):
                self.user = updatedUser
                if let token = updatedUser.approverStates.forParticipantId(participantId)?.ownerLoginIdResetToken {
                    status = .success(token)
                } else {
                    status = .failed(CensoError.failedToGenerateLoginResetToken)
                }
            case .failure(let error):
                status = .failed(error)
            }
        }
    }
}
