//
//  ShowPhrase.swift
//  Censo
//
//  Created by Brendan Flood on 10/26/23.
//

import SwiftUI

struct ShowPhrase: View {
    
    var label: String
    var seedPhrase: SeedPhrase
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

            
            switch (seedPhrase) {
            case .bip39(let words):
                Group {
                    Spacer()
                    WordList(words: words)
                        .frame(height: 250)
                }
            case .image(let imageData):
                Group {
                    if let uiImage = UIImage(data: imageData) {
                        Text("Zoom in to see the words")
                            .padding()
                        ZoomableScrollView {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(minWidth: 0, maxWidth: .infinity)
                            
                        }
                        .padding(.horizontal)
                    } else {
                        Text("Unable to render image").foregroundColor(.red)
                    }
                }
            }
            
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

#if DEBUG
#Preview("Words") {
    NavigationView {
        ShowPhrase(
            label: "Testing",
            seedPhrase: .bip39(words: ["hello", "goodbye", "three", "four"]),
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

#Preview("Image") {
    NavigationView {
        ShowPhrase(
            label: "Testing",
            seedPhrase: .image(imageData: UIImage(systemName: "photo.fill")!.jpegData(compressionQuality: 1)!),
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
#endif
