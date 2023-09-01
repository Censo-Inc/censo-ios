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
        if let deviceKeyTimestamp = try? Keychain.loadDeviceKeyTimestamp() {
            var request = request
            request.addValue(deviceKeyTimestamp.timestamp.ISO8601Format(), forHTTPHeaderField: "X-Censo-Timestamp")
            request.addValue("signature \(deviceKeyTimestamp.signature.base64EncodedString())", forHTTPHeaderField: "Authorization")
            return request
        } else {
            return request
        }
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

struct DeviceKeyTimestamp: Codable {
    var timestamp: Date
    var signature: Data
}

extension Keychain {
    private static let deviceKeyTimestampService = "co.censo.device-key-timestamp"

    static func loadDeviceKeyTimestamp() throws -> DeviceKeyTimestamp? {
        if let data = try load(account: deviceKeyTimestampService, service: deviceKeyTimestampService) {
            let decoder = JSONDecoder()
            return try decoder.decode(DeviceKeyTimestamp.self, from: data)
        } else {
            return nil
        }
    }

    static func saveDeviceKeyTimestamp(_ timestamp: DeviceKeyTimestamp) throws {
        let data = try JSONEncoder().encode(timestamp)
        try save(account: deviceKeyTimestampService, service: deviceKeyTimestampService, data: data)
    }
}

extension Notification.Name {
    static let unauthorizedNetworkCall = Self.init(rawValue: "unauthorizedNetworkCall")
}
