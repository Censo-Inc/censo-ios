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
        VStack(spacing: 30) {
            Spacer()
            
            Image("Import")
            
            Group {
                Text("Get the unique link")
                    .font(.system(size: 24))
                    .bold()
                
                Text("Please get the unique link from the seed phrase owner and tap on it, or paste it here.")
                    .font(.system(size: 14))
            }
            .multilineTextAlignment(.center)
            
            PasteLinkButton(onUrlPasted: onUrlPasted)
            
            Spacer()
        }
        .padding(.horizontal, 54)
    }
}

#if DEBUG
#Preview {
    LoggedOutPasteLinkScreen(
        onUrlPasted: { _ in }
    )
}
#endif
