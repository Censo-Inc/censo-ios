//
//  APIProvider.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-15.
//

import SwiftUI
import Moya

struct APIProviderEnvironmentKey: EnvironmentKey {
    static var defaultValue: MoyaProvider<API> = MoyaProvider(
        plugins: [
            AuthPlugin()
        ]
    )
}

extension EnvironmentValues {
    var apiProvider: MoyaProvider<API> {
        get {
            self[APIProviderEnvironmentKey.self]
        }
    }
}

struct MoyaLoadable<Value, T>: Loadable where Value : Decodable, T : Moya.TargetType {
    let target: T
    let provider: MoyaProvider<T>

    func load(_ completion: @escaping (Result<Value, Error>) -> ()) {
        provider.decodableRequest(target) { (result: Result<Value, MoyaError>) in
            switch result {
            case .success(let success):
                completion(.success(success))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
}

extension MoyaProvider {
    func loadable<V>(for target: Target) -> MoyaLoadable<V, Target> where V : Decodable {
        MoyaLoadable(target: target, provider: self)
    }
}

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSxxx"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension MoyaProvider {
    @discardableResult
    func decodableRequest<Model : Decodable>(_ target: Target, completionQueue: DispatchQueue? = nil, completion: @escaping (Result<Model, MoyaError>) -> Void) -> Moya.Cancellable {
        request(target, callbackQueue: completionQueue, progress: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response) where response.statusCode >= 400:
                debugPrint(response)
                completion(.failure(MoyaError.statusCode(response)))
            case .success(let response):
                debugPrint("Received status code: \(response.statusCode)")
                debugPrint(String(data: response.data, encoding: .utf8) ?? response.statusCode)

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(.iso8601Full)

                do {
                    let model = try decoder.decode(Model.self, from: response.data)
                    completion(.success(model))
                } catch {
                    debugPrint(error)
                    completion(.failure(MoyaError.underlying(error, response)))
                }
            }
        }
    }
}
