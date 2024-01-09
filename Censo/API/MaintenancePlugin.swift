//
//  MaintenancePlugin.swift
//  Censo
//
//  Created by imykolenko on 1/8/24.
//

import Foundation
import Moya

final class MaintenancePlugin: Moya.PluginType {
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            GlobalMaintenanceState.shared.isMaintenanceMode = response.statusCode == 418
        case .failure:
            break
        }
    }
}
