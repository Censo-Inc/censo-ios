//
//  Configuration.swift
//  Guardian
//
//  Created by Ata Namvari on 2023-09-13.
//

import Foundation

struct Configuration {
    static let apiBaseURL: URL = URLValue(for: "API_BASE_URL")
}

extension Configuration {
    static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary?["Configuration"] as? [String: Any] else {
            fatalError("`Info.plist` must contain a dictionary under `Configuration`")
        }

        return dict
    }()

    static func URLValue(for key: String) -> URL {
        guard let urlString = infoDictionary[key] as? String else {
            fatalError("`Info.plist` must contain key `\(key)`")
        }

        guard let url = URL(string: urlString) else {
            fatalError("`\(key)` is an invalid URL in `Info.plist`")
        }

        return url
    }

    static func stringValue(for key: String) -> String {
        guard let string = infoDictionary[key] as? String else {
            fatalError("`Info.plist` must contain key `\(key)`")
        }

        return string
    }

    static func dictionaryValue(for key: String) -> [String: String] {
        guard let dict = infoDictionary[key] as? [String: String] else {
            fatalError("`Info.plist` must contain a dictionary for key `\(key)`")
        }

        return dict
    }
}
