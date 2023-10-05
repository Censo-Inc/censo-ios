//
//  RecoveryExpiryCountDown.swift
//  Vault
//
//  Created by Anton Onyshchenko on 05.10.23.
//

import Foundation
import SwiftUI

struct RecoveryExpirationCountDown: View {
    var expiresAt: Date
    @State var timeRemaining: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var onTimeout: () -> Void
    
    private var formatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        return formatter
    }
    
    var body: some View {
        let formattedTime = formatter.string(from: timeRemaining)
        Text(formattedTime != nil ? "Expires in: \(formattedTime!)" : "")
            .font(.system(size: 16))
            .foregroundStyle(.white)
        .onAppear {
            timeRemaining = expiresAt.timeIntervalSinceNow
        }
        .onReceive(timer) { time in
            if (Date.now >= expiresAt) {
                onTimeout()
            } else {
                timeRemaining = expiresAt.timeIntervalSinceNow
            }
        }
    }
}

