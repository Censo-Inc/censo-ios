//
//  SeedPhotoIntro.swift
//  Censo
//
//  Created by Brendan Flood on 1/19/24.
//

import SwiftUI

struct SeedPhotoIntro: View {
    
    var onReadyToStart: () -> Void
    var onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Take a photo")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            Spacer()
                .frame(maxHeight: 50)
            
            HStack(alignment: .top, spacing: 20) {
                Image(systemName: "note.text")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .padding(12)
                    .background(.gray.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 16.0))
                
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("1. Prepare")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.bottom)
                    
                    Text("Make sure you are alone and no one else can see the paper containing your seed phrase or the screen on your phone")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom)
            
            HStack(alignment: .top) {
                
                Image("Camera")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .padding(12)
                    .background(.gray.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 16.0))
                    .padding(.trailing)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("2. Take a photo of it")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.bottom)
                    
                    Text("When you hit the **Start** button, we will present a camera to allow you to take a photo of your seed phrase.  This photo is not saved to your photo library and will only be visible to you via this app.\n\nYou will be able to review the photo before saving it.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
            
            Spacer()
            Button {
                onReadyToStart()
            } label: {
                Text("Start")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            
        }
        .padding()
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
        SeedPhotoIntro(onReadyToStart: {}, onBack: {})
            .foregroundColor(Color.Censo.primaryForeground)
    }
}
#endif
