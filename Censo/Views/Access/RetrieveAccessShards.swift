//
//  RetrieveAccessShards.swift
//  Censo
//
//  Created by Anton Onyshchenko on 30.11.23.
//

import SwiftUI
import Moya

struct RetrieveAccessShards: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    
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
                onFaceScanReady: { biometryData, completion in
                    ownerRepository.retrieveAccessShards(API.RetrieveAccessShardsApiRequest(
                        biometryVerificationId: biometryData.verificationId,
                        biometryData: biometryData
                    ), completion)
                },
                onSuccess: { response in
                    onSuccess(response.encryptedShards)
                },
                onCancelled: onCancelled
            )
        case .password:
            PasswordAuth<API.RetrieveAccessShardsWithPasswordApiResponse>(
                submit: { password, completion in
                    ownerRepository.retrieveAccessShardsWithPassword(
                        API.RetrieveAccessShardsWithPasswordApiRequest(password: password),
                        completion
                    )
                },
                onSuccess: { response in
                    onSuccess(response.encryptedShards)
                }
            )
        }
    }
}
