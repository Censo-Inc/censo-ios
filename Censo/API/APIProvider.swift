//
//  APIProvider.swift
//  Censo
//
//  Created by Ata Namvari on 2023-08-15.
//

import SwiftUI
import Moya

struct APIProviderEnvironmentKey: EnvironmentKey {
    static var defaultValue: MoyaProvider<API> = MoyaProvider(
        plugins: [
            NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration(
                formatter: .init(responseData: JSONResponseDataFormatter),
                logOptions: .verbose
            )),
            AuthPlugin(),
            ErrorResponsePlugin(),
            MaintenancePlugin(),
            FeatureFlagPlugin()
        ]
    )
}

extension EnvironmentValues {
    var apiProvider: MoyaProvider<API> {
        get {
            self[APIProviderEnvironmentKey.self]
        }
        set {
            self[APIProviderEnvironmentKey.self] = newValue
        }
    }
}
