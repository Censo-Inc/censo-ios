//
//  LoggedOutPasteLinkScreen.swift
//  Approver
//
//  Created by Anton Onyshchenko on 07.11.23.
//

import SwiftUI

struct LoggedOutPasteLinkScreen: View {
    var onUrlPasted: (URL) -> Void
    
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
                NavigationLink {
                    VStack(spacing: 30) {
                        Spacer()
                        
                        Image(systemName: "square.and.arrow.down")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 100)
                        
                        Text("To continue, the person you are assisting must send you a link.\n\nOnce you receive it, you can tap on it to continue.\n\nOr, simply copy the link to the clipboard and paste using the button below.")
                            .font(.title3)
                            .multilineTextAlignment(.center)
                        
                        PasteLinkButton(onUrlPasted: onUrlPasted)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 54)
                    
                } label: {
                    Text("Continue")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(30)
                
                Text("If instead you’re interested in using Censo to securely manage your own seed phrases, please follow **[this link](\(Configuration.ownerAppURL))** to download the Censo app.")
                    .font(.title3)
                    .tint(.black)
                    .padding(30)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#if DEBUG
#Preview {
    LoggedOutPasteLinkScreen(
        onUrlPasted: { _ in }
    )
}
#endif
