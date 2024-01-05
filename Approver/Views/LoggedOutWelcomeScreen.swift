//
//  LoggedOutWelcomeScreen.swift
//  Approver
//
//  Created by Anton Onyshchenko on 07.11.23.
//

import SwiftUI

struct LoggedOutWelcomeScreen: View {
    var onContinue: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Text("Hello Approver!")
                    .font(.largeTitle)
                Text("You've been chosen by someone to help keep their crypto safe. Please tap the continue button when you’re ready to begin helping them.")
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
                .padding(30)
                
                Text(try! AttributedString(markdown: "If instead you’re interested in using Censo to securely manage your own seed phrases, please follow **[this link](\(Configuration.ownerAppURL))** to download the Censo app."))
                    .font(.title3)
                    .padding(30)
                    .tint(.Censo.primaryForeground)
                    .multilineTextAlignment(.center)
                    .environment(\.openURL, OpenURLAction { url in
                        return .systemAction
                    })
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#if DEBUG
#Preview {
    LoggedOutWelcomeScreen(
        onContinue: {}
    )
    .foregroundColor(.Censo.primaryForeground)
}
#endif
