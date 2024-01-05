//
//  LoggedInWelcomeScreen.swift
//  Approver
//
//  Created by Anton Onyshchenko on 05.01.24.
//

import Foundation
import SwiftUI

struct LoggedInWelcomeScreen: View {
    var session: Session
    @Binding var user: API.ApproverUser
    var onContinue: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Hello Approver!")
                    .font(.largeTitle)
                Text("You’re helping someone who trusts you keep their crypto safe.\n\nPlease tap the continue button when they contact you.")
                    .font(.title3)
                    .padding(30)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding()
                
                ApproverStatus(active: user.isActiveApprover)
                
                Spacer()
                
                NavigationLink {
                    Settings(session: session, user: $user)
                } label: {
                    HStack {
                        Image("SettingsFilled").renderingMode(.template)
                        Text("Settings")
                            .font(.title3)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom)
            }
            .padding()
        }
    }
}
