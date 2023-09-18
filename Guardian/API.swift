//
//  API.swift
//  Guardian
//
//  Created by Ata Namvari on 2023-09-13.
//

import Foundation
import Moya
import SwiftUI

enum API {
    case registerDevice(inviteCode: String, deviceKey: DeviceKey)
    case guardianState(deviceKey: DeviceKey)
}

extension API: TargetType {
    var baseURL: URL {
        Configuration.apiBaseURL
    }

    var path: String {
        switch self {
        case .registerDevice(let inviteCode, _):
            return "v1/invitation/\(inviteCode)"
        case .guardianState:
            return "v1/"
        }
    }

    var method: Moya.Method {
        switch self {
        case .registerDevice:
            return .post
        case .guardianState:
            return .get
        }
    }

    var task: Moya.Task {
        switch self {
        case .registerDevice,
             .guardianState:
            return .requestPlain
        }
    }

    var headers: [String : String]? {
        switch self {
        case .registerDevice(_, let deviceKey),
             .guardianState(let deviceKey):
            let timestamp = Date()
            let timestampString = timestamp.ISO8601Format()
            let signature = try? deviceKey.signature(for: timestampString.data(using: .utf8) ?? Data())

            return [
                "Content-Type": "application/json",
                "X-IsApi": "true",
                "X-Censo-OS-Version": UIDevice.current.systemVersion,
                "X-Censo-Device-Type": UIDevice.current.systemName,
                "X-Censo-App-Version": Bundle.main.shortVersionString,
                "X-Censo-Device-Public-Key": (try? deviceKey.publicExternalRepresentation().base58EncodedString()) ?? "",
                "X-Censo-Timestamp": timestampString,
                "Authorization": "signature \(signature?.base58EncodedString() ?? "")"
            ]
        }
    }
}

extension Data {
    func base58EncodedString() -> String {
        Base58.encode(bytes)
    }
}

extension Bundle {
    var shortVersionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}

struct APIProviderEnvironmentKey: EnvironmentKey {
    static var defaultValue: MoyaProvider<API> = MoyaProvider()
}

extension EnvironmentValues {
    var apiProvider: MoyaProvider<API> {
        get {
            self[APIProviderEnvironmentKey.self]
        }
    }
}
