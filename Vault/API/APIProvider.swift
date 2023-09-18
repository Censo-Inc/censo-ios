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
