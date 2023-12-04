//
//  RetrieveRecoveryShards.swift
//  Censo
//
//  Created by Anton Onyshchenko on 30.11.23.
//

import SwiftUI
import Moya
import raygun4apple

struct RetrieveRecoveredShards: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onSuccess: ([API.EncryptedShard]) -> Void
    var onCancelled: () -> Void
    
    var body: some View {
        switch ownerState.authType {
        case .none:
            EmptyView().onAppear {
                onCancelled()
            }
        case .facetec:
            FacetecAuth<API.RetrieveRecoveryShardsApiResponse>(
                session: session,
                onReadyToUploadResults: { biomentryVerificationId, biometryData in
                    return .retrieveRecoveredShards(API.RetrieveRecoveryShardsApiRequest(
                        biometryVerificationId: biomentryVerificationId,
                        biometryData: biometryData
                    ))
                },
                onSuccess: { response in
                    onSuccess(response.encryptedShards)
                },
                onCancelled: onCancelled
            )
        case .password:
            GetPassword { cryptedPassword, onComplete in
                apiProvider.decodableRequest(
                    with: session,
                    endpoint: .retrieveRecoveredShardsWithPassword(
                        API.RetrieveRecoveryShardsWithPasswordApiRequest(
                            password: API.Password(cryptedPassword: cryptedPassword)
                        )
                    )
                )
                { (result: Result<API.RetrieveRecoveryShardsWithPasswordApiResponse, MoyaError>) in
                    switch result {
                    case .failure(MoyaError.underlying(CensoError.validation("Incorrect password"), _)):
                        onComplete(false)
                    case .failure:
                        onCancelled()
                        onComplete(true)
                    case .success(let response):
                        onSuccess(response.encryptedShards)
                        onComplete(true)
                    }
                }
            }
        }
    }
}
