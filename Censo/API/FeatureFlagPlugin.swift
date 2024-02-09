//
//  FeatureFlagPlugin.swift
//  Censo
//
//  Created by Brendan Flood on 2/6/24.
//

import Foundation
import Moya

final class FeatureFlagPlugin: Moya.PluginType {
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response) where response.statusCode < 205:
            if let httpUrlResponse = response.response,
            let features = httpUrlResponse.value(forHTTPHeaderField: "X-Censo-Feature-Flags") {
                   let features = features.split(separator: ",").map({String($0).trimmingCharacters(in: .whitespaces)})
                   if features != FeatureFlagState.shared.features {
                       FeatureFlagState.shared.features = features
                   }
            }
        default:
            break
        }
    }
}
