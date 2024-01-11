//
//  MaintenanceView.swift
//  Censo
//
//  Created by imykolenko on 1/8/24.
//

import Combine
import SwiftUI

struct MaintenanceView: View {
    
    @ObservedObject var globalMaintenanceState = MaintenanceState.shared
    
    @State private var timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {

        if (globalMaintenanceState.isOn) {

            VStack {
                Text("Censo is currently under maintenance, please try again in a few minutes.")
                    .padding()
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
            .background(Color(UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1)))
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
        MaintenanceView()
    }
    .foregroundColor(.Censo.primaryForeground)
}
#endif
