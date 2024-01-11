//
//  MaintenanceView.swift
//  Censo
//
//  Created by imykolenko on 1/8/24.
//

import Combine
import SwiftUI

struct MaintenanceView: View {
    @ObservedObject var maintenanceState = MaintenanceState.shared
    @State private var showMaintenanceView: Bool = false
    
    @State private var timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Group {
            if showMaintenanceView {
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
                    NotificationCenter.default.post(name: Notification.Name.maintenanceStatusCheckNotification, object: nil)
                }
            }
        }
        .opacity(showMaintenanceView ? 1 : 0)
        .onChange(of: maintenanceState.isOn) { isMaintenanceMode in
            if !isMaintenanceMode {
                // Delay to allow for retry under the maintenance screen
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showMaintenanceView = false
                }
            } else {
                showMaintenanceView = true
                timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
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
