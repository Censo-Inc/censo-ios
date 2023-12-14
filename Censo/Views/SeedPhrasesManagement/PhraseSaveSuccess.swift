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
        VStack(spacing: 0) {
            Spacer()
            ZStack(alignment: .top) {
                Image("CenteredCongrats")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                GeometryReader { geometry in
                    Text("Congrats!")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, geometry.size.height * 0.17)
                        .padding(.leading, geometry.size.width * 0.3)
                }
            }.multilineTextAlignment(.center)
            
            if isFirstTime {
                Text("You'll never have to worry about losing access to your valuable crypto again.")
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
        .foregroundColor(Color.Censo.primaryForeground)
    }
    
}
#endif
