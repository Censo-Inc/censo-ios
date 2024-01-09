//
//  ShowPhrase.swift
//  Censo
//
//  Created by Brendan Flood on 10/26/23.
//

import SwiftUI

struct ShowPhrase: View {
    
    var label: String
    var words: [String]
    var onComplete: (Bool) -> Void
    var start: Date
    
    var body: some View {
        VStack {
            HStack {
                Image("HourGlass")
                    .renderingMode(.template)
                AccessExpirationCountdown(
                    expiresAt: start.addingTimeInterval(TimeInterval(900)),
                    onExpired: {
                        onComplete(false)  
                    },
                    onBackgrounded: {
                        onComplete(false)
                    }
                )
            }
            .frame(width: 430, height: 64)
            .background(Color.Censo.gray224)
            
            Spacer()
            
            WordList(words: words)
                .frame(height: 250)
            
            Group {
                Divider()
                Button {
                    onComplete(true)
                } label: {
                    Text("Done viewing phrase")
                        .font(.title2)
                        .padding([.horizontal])
                }
                .buttonStyle(RoundedButtonStyle())
                .padding()
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
            onComplete: {_ in},
            start: Date.now
        )
        .navigationTitle(Text("Access"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                } label: {
                    Image(systemName: "xmark")
                }
            }
        })
    }.foregroundColor(Color.Censo.primaryForeground)
}
