//
//  RefreshOnTimer.swift
//  Censo
//
//  Created by Brendan Flood on 11/28/23.
//

import SwiftUI

import Combine

struct RefreshOnTimer: ViewModifier {
    @Environment(\.scenePhase) var scenePhase
    @Binding var timer: Publishers.Autoconnect<Timer.TimerPublisher>
    var interval: TimeInterval
    var refresh: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { newScenePhase in
                switch newScenePhase {
                case .active:
                    timer = Timer.publish(every: interval, on: .main, in: .common).autoconnect()
                case .inactive,
                        .background:
                    timer.upstream.connect().cancel()
                default:
                    break;
                }
            }
            .onReceive(timer) { _ in
                refresh()
            }
    }
}
