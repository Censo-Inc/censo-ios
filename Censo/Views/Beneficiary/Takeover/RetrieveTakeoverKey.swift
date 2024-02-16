//
//  RetrieveTakeoverKey.swift
//  Censo
//
//  Created by Brendan Flood on 2/14/24.
//

import SwiftUI
import Moya

struct RetrieveTakeoverKey: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    
    var authType: API.AuthType
    var onSuccess: (Base64EncodedString, API.Authentication.Password?) -> Void
    var onCancelled: () -> Void
    
    @State private var password: API.Authentication.Password?
    
    var body: some View {
        switch authType {
        case .none:
            EmptyView().onAppear {
                onCancelled()
            }
        case .facetec:
            FacetecAuth<API.RetrieveTakeoverKeyApiResponse>(
                onFaceScanReady: { biometryData, completion in
                    ownerRepository.retrieveTakeoverKey(API.RetrieveTakeoverKeyApiRequest(
                        biometryData: biometryData
                    ), completion)
                },
                onSuccess: { response in
                    onSuccess(response.encryptedKey, nil)
                },
                onCancelled: onCancelled
            )
        case .password:
            PasswordAuth<API.RetrieveTakeoverKeyWithPasswordApiResponse>(
                submit: { password, completion in
                    self.password = password
                    ownerRepository.retrieveTakeoverKeyWithPassword(
                        API.RetrieveTakeoverKeyWithPasswordApiRequest(password: password),
                        completion
                    )
                },
                onSuccess: { response in
                    onSuccess(response.encryptedKey, self.password)
                }
            )
        }
    }
}
