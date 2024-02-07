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
        VStack(spacing: 0) {
            Spacer()
            
            Text("Let's take a photo of your seed phrase")
                .padding(.vertical)
                .padding(.horizontal, 32)

            Spacer()
            
            content()
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal)
            
            Spacer()
            
            Button {
                onTakePhoto()
            } label: {
                Text("Take a photo")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(.vertical)
            .padding(.horizontal, 32)
            .accessibilityIdentifier("takeAPhoto")
            
            Spacer()
        }
        .navigationTitle(Text("Seed phrase photo"))
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
