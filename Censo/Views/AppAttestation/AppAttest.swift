//
//  AppAttest.swift
//  Censo
//
//  Created by Ata Namvari on 2023-11-16.
//

import SwiftUI
import DeviceCheck
import Moya
import CryptoKit

fileprivate let challengeHeader = "X-Censo-Challenge"
fileprivate let appleAssertionHeader = "X-Censo-Apple-Attestation"
fileprivate let requiresAssertionHeader = "Requires-Assertion"

struct AppAttest<Content>: View where Content : View {
    @Environment(\.apiProvider) var apiProvider

    @AppStorage private var attestKey: AttestKey?

    var session: Session
    var content: () -> Content

    init(session: Session, @ViewBuilder content: @escaping () -> Content) {
        self.session = session
        self.content = content
        self._attestKey = AppStorage("attestKey-\(session.userCredentials.userIdentifier)")
    }

    var body: some View {
        if let attestKey = attestKey {
            if attestKey.verified {
                AttestationCheck(session: session, keyId: attestKey.keyId) {
                    self.attestKey = nil
                } content: {
                    content()
                        .environment(\.apiProvider, MoyaProvider(
                            endpointClosure: assertedEndpointClosure(),
                            requestClosure: assertedRequestClosure(keyId: attestKey.keyId),
                            plugins: apiProvider.plugins)
                        )
                }
            } else {
                AttestKeyVerification(session: session, keyId: attestKey.keyId) {
                    self.attestKey?.verified = true
                } onKeyError: {
                    self.attestKey = nil
                }
            }
        } else {
            AttestKeyGeneration { attestKey in
                self.attestKey = attestKey
            }
        }
    }

    func assertedEndpointClosure() -> MoyaProvider<API>.EndpointClosure {
        { target in
            var endpoint = MoyaProvider<API>.defaultEndpointMapping(for: target)
            
            if target.requiresAssertion {
                return endpoint.adding(newHTTPHeaderFields: [requiresAssertionHeader: "YES"])
            } else {
                return endpoint
            }
        }
    }

    func assertedRequestClosure(keyId: String) -> MoyaProvider<API>.RequestClosure {
        { endpoint, requestResultClosure in
            do {
                var request = try endpoint.urlRequest()

                guard endpoint.httpHeaderFields?[requiresAssertionHeader] != nil else {
                    request.headers.remove(name: requiresAssertionHeader)
                    requestResultClosure(.success(request))
                    return
                }

                request.headers.remove(name: requiresAssertionHeader)

                apiProvider.decodableRequest(with: session, endpoint: .attestationChallenge) { (result: Result<API.AttestationChallenge, MoyaError>) in
                    switch result {
                    case .success(let attestation):
                        let challenge = attestation.challenge
                        let requestPath = request.url?.path() ?? ""
                        let requestQuery = request.url?.query().flatMap { "?\($0)" } ?? ""
                        let requestBody = request.httpBody?.base64EncodedString() ?? ""
                        let dataToSign = "\(request.httpMethod ?? "GET")\(requestPath)\(requestQuery)\(requestBody)\(challenge.value)".data(using: .utf8)!
                        let clientDataHash = Data(SHA256.hash(data: dataToSign))

                        DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientDataHash) { data, error in
                            guard error == nil else {
                                requestResultClosure(.failure(.underlying(error!, nil)))
                                return
                            }

                            request.headers.add(name: challengeHeader, value: attestation.challenge.value)
                            request.headers.add(name: appleAssertionHeader, value: data!.base64EncodedString())

                            requestResultClosure(.success(request))
                        }
                    case .failure(let error):
                        requestResultClosure(.failure(error))
                    }
                }
            } catch {
                requestResultClosure(.failure(.underlying(error, nil)))
            }
        }
    }
}
