//
//  Maintenance.swift
//  Censo
//
//  Created by imykolenko on 1/8/24.
//

import Foundation


class MaintenanceState: ObservableObject {
    static let shared = MaintenanceState()
    @Published var isOn: Bool = false {
        didSet {
            if oldValue != isOn {
                maintenanceModeChange = (oldValue, isOn)
            }
        }
    }
    @Published var maintenanceModeChange: (oldValue: Bool, newValue: Bool) = (false, false)
}
