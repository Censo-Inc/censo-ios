//
//  AuthPlugin.swift
//  Censo
//
//  Created by Ata Namvari on 2023-08-31.
//

import Foundation
import Moya

struct AuthPlugin: Moya.PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let target = target as? API else {
            return request
        }

        let deviceKey = target.deviceKey

        var request = request

        let timestampString = Date().ISO8601Format()
        let requestPath = request.url?.path() ?? ""
        let requestQuery = request.url?.query().flatMap { "?\($0)" } ?? ""
        let requestBody = request.httpBody?.base64EncodedString() ?? ""
        let dataToSign = "\(request.httpMethod ?? "GET")\(requestPath)\(requestQuery)\(requestBody)\(timestampString)".data(using: .utf8)
        let signature = dataToSign.flatMap { try? deviceKey.signature(for: $0) }?.value ?? "[CORRUPT_DEVICE_KEY]"

        request.addValue(timestampString, forHTTPHeaderField: "X-Censo-Timestamp")
        request.addValue("signature \(signature)", forHTTPHeaderField: "Authorization")
        request.addValue((try? deviceKey.publicExternalRepresentation().base58EncodedString()) ?? "", forHTTPHeaderField: "X-Censo-Device-Public-Key")

        return request
    }

    enum SignatureError: Error {
        case corruptDeviceKey
    }

    func process(_ result: Result<Moya.Response, MoyaError>, target: TargetType) -> Result<Moya.Response, MoyaError> {
        switch (result, target) {
        case (.success(let response), _) where response.statusCode == 401:
            debugPrint("401 unauthorized:", String(data: response.data, encoding: .utf8)!)

            defer { NotificationCenter.default.post(name: .unauthorizedNetworkCall, object: nil) }

            if response.request?.headers["Authorization"] == "signature [CORRUPT_DEVICE_KEY]" {
                return .failure(.underlying(SignatureError.corruptDeviceKey, response))
            } else {
                return result
            }
        default:
            return result
        }
    }
}

extension Notification.Name {
    static let unauthorizedNetworkCall = Self.init(rawValue: "unauthorizedNetworkCall")
}
