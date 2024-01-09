//
//  Maintenance.swift
//  Censo
//
//  Created by imykolenko on 1/8/24.
//

import Foundation


class GlobalMaintenanceState: ObservableObject {
    static let shared = GlobalMaintenanceState()
    @Published var isMaintenanceMode: Bool = false
}
