//
//  View+DismissableAlert.swift
//  Censo
//
//  Created by imykolenko on 1/11/24.
//

import SwiftUI
import Moya

extension View {
    
    func dismissableAlert(
        isPresented: Binding<Bool>,
        error: Binding<Error?>,
        okAction: @escaping () -> Void
    ) -> some View {
        return self
            .alert("Error", isPresented: isPresented, presenting: error.wrappedValue) { _ in
                Button {
                    okAction()
                } label: { Text("OK") }
            } message: { error in
                Text(error.localizedDescription)
            }
            .onReceive(MaintenanceState.shared.$maintenanceModeChange) { modeChange in
                // Dismiss only CensoError.underMaintenance when maintenance mode has changed
                if let errorValue = error.wrappedValue as? MoyaError,
                    case .underlying(CensoError.underMaintenance, _) = errorValue {
                    if modeChange.oldValue && !modeChange.newValue {
                        okAction()
                    }
                }
            }
    }
}
