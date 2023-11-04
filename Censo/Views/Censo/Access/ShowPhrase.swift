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
            }
            .frame(width: 430, height: 64)
            .background(Color.Censo.gray224)
            
            Spacer()
            
            WordList(words: words)
            
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
            onComplete: {_ in}
        )
        .navigationTitle(Text("Access"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                }
            }
        })
    }
}
