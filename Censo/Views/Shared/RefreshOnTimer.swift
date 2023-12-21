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
    var refresh: () -> Void
    var isIdleTimerDisabled: Bool = false
    
    func body(content: Content) -> some View {
        var identifier: UIBackgroundTaskIdentifier? = nil
        
        content
            .onChange(of: scenePhase) { newScenePhase in
                switch newScenePhase {
                case .active, .inactive:
                    if identifier != nil {
                        UIApplication.shared.endBackgroundTask(identifier!)
                    }
                    break
                case .background:
                    identifier = UIApplication.shared.beginBackgroundTask {
                        UIApplication.shared.endBackgroundTask(identifier!)
                    }
                @unknown default:
                    break;
                }
            }
            .onReceive(timer) { _ in
                refresh()
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = isIdleTimerDisabled
            }
            .onDisappear {
                if identifier != nil {
                    UIApplication.shared.endBackgroundTask(identifier!)
                }
                timer.upstream.connect().cancel()
                UIApplication.shared.isIdleTimerDisabled = false
            }
    }
}
