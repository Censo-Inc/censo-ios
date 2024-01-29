//
//  RetrieveAccessShards.swift
//  Censo
//
//  Created by Anton Onyshchenko on 30.11.23.
//

import SwiftUI
import Moya

struct RetrieveAccessShards: View {
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
            FacetecAuth<API.RetrieveAccessShardsApiResponse>(
                session: session,
                onReadyToUploadResults: { biometryData in
                    return .retrieveAccessShards(API.RetrieveAccessShardsApiRequest(
                        biometryVerificationId: biometryData.verificationId,
                        biometryData: biometryData
                    ))
                },
                onSuccess: { response in
                    onSuccess(response.encryptedShards)
                },
                onCancelled: onCancelled
            )
        case .password:
            PasswordAuth<API.RetrieveAccessShardsWithPasswordApiResponse>(
                session: session,
                submitTo: { password in
                    return .retrieveAccessShardsWithPassword(
                        API.RetrieveAccessShardsWithPasswordApiRequest(
                            password: password
                        )
                    )
                },
                onSuccess: { response in
                    onSuccess(response.encryptedShards)
                }
            )
        }
    }
}
