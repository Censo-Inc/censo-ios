//
//  TakePhoto.swift
//  Censo
//
//  Created by Brendan Flood on 1/19/24.
//

import SwiftUI
import AVFoundation

struct TakeSeedPhoto<Content: View>: View {
    
    var onTakePhoto: () -> Void
    var onBack: () -> Void
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Let's take a photo of your seed phrase")

            Spacer()
            
            content()
            
            Group {
                Divider()
                Button {
                    onTakePhoto()
                } label: {
                    Text("Take a Photo")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding()
                .accessibilityIdentifier("takeAPhoto")
            }
            .padding()
            .frame(maxHeight: 80, alignment: .bottom)
        }
        .navigationTitle(Text("Seed Phrase Photo"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        TakeSeedPhoto(onTakePhoto: {}, onBack:{}) {
            Image(systemName: "photo.fill")
                .resizable()
                .scaledToFit()
                .opacity(0.6)
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding(.horizontal)
        }
    }
}
#endif
