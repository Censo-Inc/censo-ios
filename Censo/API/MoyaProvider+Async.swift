//
//  MoyaProvider+Async.swift
//  Censo
//
//  Created by Ata Namvari on 2023-11-16.
//

import Foundation
import Moya

extension MoyaProvider {
    func decodableRequest<T>(_ target: Target) async throws -> T where T : Decodable {
        try await withCheckedThrowingContinuation { continuation in
            decodableRequest(target) { (result: Result<T, MoyaError>) in
                continuation.resume(with: result)
            }
        }
    }

    func request(_ target: Target) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            request(target) { result in
                continuation.resume(with: result)
            }
        }
    }
}
