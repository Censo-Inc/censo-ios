//
//  AuthPlugin.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-31.
//

import Foundation
import Moya

struct AuthPlugin: Moya.PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        if let deviceKey = SecureEnclaveWrapper.deviceKey() {
            return addAuthHeaders(request: request, deviceKey: deviceKey)
        } else {
            return request
        }
    }
    private func addAuthHeaders(request: URLRequest, deviceKey: DeviceKey) -> URLRequest {
        var request = request
        let timestamp = Date()
        let timestampString = timestamp.ISO8601Format()
        let requestPath = request.url?.path ?? ""
        let requestQuery = request.url?.query == nil ? "" : "?\(request.url!.query!)"
        let requestBody = (request.httpBody ?? Data()).base64EncodedString()
        let dataToSign = ((request.httpMethod ?? "") + requestPath + requestQuery + requestBody + timestampString).data(using: .utf8) ?? Data()
        let signature = (try? deviceKey.signature(for: dataToSign))?.base64EncodedString() ?? ""
        request.addValue(timestampString, forHTTPHeaderField: "X-Censo-Timestamp")
        request.addValue("signature \(signature)", forHTTPHeaderField: "Authorization")
        return request
    }

    func process(_ result: Result<Moya.Response, MoyaError>, target: Moya.TargetType) -> Result<Moya.Response, MoyaError> {
        switch (result, target) {
        case (.success(let response), _) where response.statusCode == 401:
            debugPrint("401 unauthorized:", String(data: response.data, encoding: .utf8)!)
            defer { NotificationCenter.default.post(name: .unauthorizedNetworkCall, object: nil) }
            return result
        default:
            return result
        }
    }
}

extension Notification.Name {
    static let unauthorizedNetworkCall = Self.init(rawValue: "unauthorizedNetworkCall")
}
