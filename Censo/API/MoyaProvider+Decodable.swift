//
//  MoyaProvider+Decodable.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-13.
//

import Foundation
import Moya

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

func JSONResponseDataFormatter(_ data: Data) -> String {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return String(data: prettyData, encoding: .utf8) ?? String(data: data, encoding: .utf8) ?? ""
    } catch {
        return String(data: data, encoding: .utf8) ?? ""
    }
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
