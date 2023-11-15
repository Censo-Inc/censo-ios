//
//  PhraseSaveSuccess.swift
//  Censo
//
//  Created by Ata Namvari on 2023-10-19.
//

import SwiftUI

struct PhraseSaveSuccess: View {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var isFirstTime: Bool
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 100)

            if isFirstTime {
                Text("Congratulations!\n\nYou'll never have to worry about losing access to your valuable crypto again.")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(30)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Your seed phrase is securely stored.\n\nIt can be accessed only by you.")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(30)
                    .fixedSize(horizontal: false, vertical: true)                
            }
            Spacer()
            Button() {
#if DEBUG
                if isFirstTime && !appDelegate.testing {
                    handlePushRegistration()
                }
#else
                if isFirstTime {
                    handlePushRegistration()
                }
#endif
                onFinish()
            } label: {
                Text("OK")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(30)
        }
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .navigationBarBackButtonHidden(true)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    onFinish()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                }
            }
        })
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
struct PhraseSaveSuccess_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PhraseSaveSuccess(isFirstTime: true) {}
        }
    }
}
#endif
