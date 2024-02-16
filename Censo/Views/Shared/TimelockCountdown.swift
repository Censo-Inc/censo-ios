//
//  TimelockCountdown.swift
//  Censo
//
//  Created by Brendan Flood on 1/5/24.
//

import Foundation
import SwiftUI

struct TimelockCountdown : View {
    @Environment(\.scenePhase) var scenePhase
    var expiresAt: Date
    @State var timeRemaining: TimeInterval = 0
    @State var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var onExpired: () -> Void
    
    var body: some View {
        Text("Timelock expires in: **\(formatTimelockDisplay(timeRemaining: timeRemaining))**")
            .font(.system(size: 16))
            .onChange(of: scenePhase) { newScenePhase in
                switch newScenePhase {
                case .active:
                    timeRemaining = expiresAt.timeIntervalSinceNow
                default:
                    break;
                }
            }
            .onAppear {
                timeRemaining = expiresAt.timeIntervalSinceNow
            }
            .onReceive(timer) { time in
                if (Date.now >= expiresAt) {
                    onExpired()
                } else {
                    timeRemaining = expiresAt.timeIntervalSinceNow
                }
            }
    }
}

#Preview {
    TimelockCountdown(
        expiresAt: Date.now.addingTimeInterval(TimeInterval(50)),
        onExpired: {}
    )
}



