//
//  SeedPhotoVerification.swift
//  Censo
//
//  Created by Brendan Flood on 1/18/24.
//

import SwiftUI

struct SeedPhotoVerification: View {
    var imageData: Data
    var onSubmit: (Data) -> Void
    var onRetake: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            if let uiImage = UIImage(data: imageData) {
                Text("Zoom in to review the words")
                    .padding()
                
                ZoomableScrollView {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
                .padding()
            } else {
                Text("Unable to render image").foregroundColor(.red)
            }
            
            Spacer()
            
            Group {
                Button {
                    onSubmit(imageData)
                } label: {
                    Text("Use photo")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.bottom)
                .accessibilityIdentifier("usePhoto")
                
                Button {
                    onRetake()
                } label: {
                    Text("Retake")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.bottom)
                .accessibilityIdentifier("retakePhoto")
            }
            .padding(.horizontal, 32)
        }
        .multilineTextAlignment(.leading)
        .navigationInlineTitle("Seed phrase photo verification")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                DismissButton(icon: .back, action: onRetake)
            }
        }
    }
}


#if DEBUG
#Preview {
    NavigationStack {
        SeedPhotoVerification(imageData: UIImage(systemName: "photo.fill")!.jpegData(compressionQuality: 1)!, onSubmit: {_ in }, onRetake: {}) .foregroundColor(.Censo.primaryForeground)
    }
}
#endif
