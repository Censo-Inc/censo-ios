//
//  PushNotificationSettings.swift
//  Censo
//
//  Created by Brendan Flood on 12/15/23.
//

import SwiftUI

struct PushNotificationSettings: View {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var onFinish: () -> Void
    @AppStorage("pushNotificationsEnabled") var pushNotificationsEnabled: String?
    
    var body: some View {
            
        if pushNotificationsEnabled != "true" {
            VStack(alignment: .leading) {
                Text("Allow Push Notifications")
                    .font(.title)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 20)
                
                Text("Because you are anonymous, and we don’t have your email address or phone number, the only way that Censo can communicate to you is with in-app notifications.")
                    .font(.title3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical)
                
                Text("We will never send you marketing communications, but we might need to notify you about security or other important updates. Please tap the button below to enable notifications.")
                    .font(.title3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical)
                
                Spacer ()
                
                Button {
                    pushNotificationsEnabled = "true"
#if DEBUG
                    if !appDelegate.testing {
                        handlePushRegistration()
                    }
#else
                    handlePushRegistration()
#endif
                    onFinish()
                } label: {
                    Text("Enable notifications")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .accessibilityIdentifier("enableButton")

                Button {
                    pushNotificationsEnabled = "false"
                    onFinish()
                } label: {
                    Text("No thanks")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical)
                .buttonStyle(RoundedButtonStyle())
                .accessibilityIdentifier("noThanksButton")
            }
            .padding(.horizontal, 25)
        } else {
            ProgressView()
                .onAppear {
                    onFinish()
                }
        }
    }
    
    private func handlePushRegistration() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (result, _) in
                        if result {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        }
                    }
                } else if settings.authorizationStatus == .authorized {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    PushNotificationSettings(onFinish: {})
}
#endif
