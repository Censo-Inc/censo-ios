//
//  API.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-15.
//

import Foundation
import Moya
import UIKit

enum API {
    case minVersion

    case user
    case createDevice
    case createUser(name: String)
    case createContact(type: Contact.`Type`, value: String)
    case verifyContact(Contact, code: String)
    case registerPushToken(String)
}

extension API: TargetType {
    var baseURL: URL {
        switch self {
        case .minVersion:
            return Configuration.minVersionURL
        default:
            return Configuration.apiBaseURL
        }
    }

    var path: String {
        switch self {
        case .minVersion:
            return ""
        case .createContact:
            return "v1/contacts"
        case .createUser,
             .user:
            return "v1/user"
        case .verifyContact(let contact, _):
            return "v1/contacts/\(contact.identifier)/verification-code"
        case .createDevice:
            return "v1/device"
        case .registerPushToken:
            return "v1/notification-tokens"
        }
    }

    var method: Moya.Method {
        switch self {
        case .minVersion,
             .user:
            return .get
        case .createUser,
             .createContact,
             .verifyContact,
             .createDevice,
             .registerPushToken:
            return .post
        }
    }

    var task: Moya.Task {
        switch self {
        case .minVersion,
             .user,
             .createDevice:
            return .requestPlain
        case .createUser(let name):
            return .requestJSONEncodable([
                "name": name
            ])
        case .createContact(let type, let value):
            return .requestJSONEncodable([
                "contactType": type.rawValue,
                "value": value
            ])
        case .verifyContact(_, let code):
            return .requestJSONEncodable([
                "verificationCode": code
            ])
        case .registerPushToken(let token):
            return .requestJSONEncodable([
                "token": token,
                "deviceType": "Ios"
            ])
        }
        
    }

    var headers: [String : String]? {
        return [
            "Content-Type": "application/json",
            "X-IsApi": "true",
            "X-Censo-OS-Version": UIDevice.current.systemVersion,
            "X-Censo-Device-Type": UIDevice.current.systemName,
            "X-Censo-App-Version": Bundle.main.shortVersionString
        ]
    }
}

extension Bundle {
    var shortVersionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}
