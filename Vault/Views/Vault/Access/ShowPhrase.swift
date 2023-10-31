//
//  ShowPhrase.swift
//  Vault
//
//  Created by Brendan Flood on 10/26/23.
//

import SwiftUI

struct ShowPhrase: View {
    
    var label: String
    var words: [String]
    var onComplete: (Bool) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Image("HourGlass")
                AccessExpirationCountdown(
                    onExpired: {
                        onComplete(false)
                    },
                    onBackgrounded: {
                        onComplete(false)
                    }
                )
                .frame(width: 240, height: 4)
                Button {
                    onComplete(true)
                } label: {
                    Text("Done")
                        .frame(width: 50, height: 4)
                }
                .buttonStyle(RoundedButtonStyle())
            }
            .frame(width: 430, height: 64)
            .background(Color.Censo.gray224)
            
            Spacer()
            
            WordList(words: words)
            
            Group {
                Divider()
                SetupStep(image: Image("AccessWarning"), heading: "Don't leave the app", content: "You will need to scan your face again if you leave or close the app.", opacity: 1.0)
            }
            .frame(maxHeight: 80, alignment: .bottom)
            .padding()
            
        }
    }
    
}

#Preview {
    NavigationView {
        ShowPhrase(
            label: "Testing",
            words: ["hello", "goodbye", "three", "four"],
            onComplete: {_ in}
        )
    }
}
