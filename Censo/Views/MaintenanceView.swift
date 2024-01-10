//
//  MaintenanceView.swift
//  Censo
//
//  Created by imykolenko on 1/8/24.
//

import Combine
import SwiftUI
import Moya

struct MaintenanceView: View {
    
    @ObservedObject var globalMaintenanceState = GlobalMaintenanceState.shared
    
    @State private var timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {

        if (globalMaintenanceState.isMaintenanceMode) {

            VStack {
                Text("Censo is currently under maintenance, please try again in a few minutes.")
                    .padding()
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
            .background(Color.green.opacity(0.25))
            .disabled(true)
            .onAppear {
                timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
            }
            .onDisappear {
                timer.upstream.connect().cancel()
            }
            .onReceive(timer) { _ in
                // session is not available in this place, notify logged in view to perfrom an API call
                NotificationCenter.default.post(name: Notification.Name.maintenanceStatusCheckNotification, object: nil)
            }
        }
        
    }
}

#if DEBUG
#Preview {
    NavigationView {
        MaintenanceView(
            //session: .sample
        )
    }
    .foregroundColor(.Censo.primaryForeground)
}
#endif
