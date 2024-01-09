//
//  MaintenanceOverlayView.swift
//  Censo
//
//  Created by imykolenko on 1/8/24.
//

import Combine
import SwiftUI
import Moya

struct MaintenanceOverlayView: View {
    @Environment(\.apiProvider) var apiProvider
    var session: Session
    
    @State private var cancellables = Set<AnyCancellable>()
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("Censo is currently under maintenance, please try again in a few minutes.")
                .padding()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .background(Color.green)
        .disabled(true)
        .onAppear {
            self.timer.upstream.connect().store(in: &cancellables)
        }
        .onDisappear {
            self.timer.upstream.connect().cancel()
        }
        .onReceive(timer) { _ in
            // response code will be handled by Moya plugin updating GlobalMaintenanceState
            apiProvider.request(with: session, endpoint: .user) { _ in }
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        MaintenanceOverlayView(
            session: .sample
        )
    }
    .foregroundColor(.Censo.primaryForeground)
}
#endif
