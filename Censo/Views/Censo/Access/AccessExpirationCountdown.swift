//
//  AccessExpirationCountdown.swift
//  Censo
//
//  Created by Brendan Flood on 10/26/23.
//

import Foundation
import SwiftUI

struct AccessExpirationCountdown: View {
    @Environment(\.scenePhase) var scenePhase
    
    var expiresAt: Date = Date.now.addingTimeInterval(TimeInterval(900))
    @State var timeRemaining: TimeInterval = 0
    @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var onExpired: () -> Void
    var onBackgrounded: () -> Void
    
    private var formatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.minute]
        return formatter
    }
    
    var body: some View {
        let formattedTime = formatter.string(from: timeRemaining)
        Text(formattedTime != nil ? "Access ends in: **\(timeRemaining.isLess(than: TimeInterval(119)) ? "less than 1 minute" : formattedTime!)**" : "")
        .font(.system(size: 16))
        .foregroundStyle(.black)
        .onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .active:
                timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            case .inactive:
                timer.upstream.connect().cancel()
            case .background:
                timer.upstream.connect().cancel()
                onBackgrounded()
            default:
                break;
            }
        }
        .onAppear {
            timeRemaining = expiresAt.timeIntervalSinceNow + 59
        }
        .onReceive(timer) { time in
            if (Date.now >= expiresAt) {
                onExpired()
            } else {
                timeRemaining = expiresAt.timeIntervalSinceNow + 59
            }
        }
    }
}

#Preview {
    AccessExpirationCountdown(onExpired: {}, onBackgrounded: {})
}


