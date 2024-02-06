//
//  SeedPhotoVerification.swift
//  Censo
//
//  Created by Brendan Flood on 1/18/24.
//

import SwiftUI

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
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal)
                .padding(.bottom)
                .accessibilityIdentifier("usePhoto")
                
                Button {
                    onRetake()
                } label: {
                    Text("Retake")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal)
                .padding(.bottom)
                .accessibilityIdentifier("retakePhoto")
            }
        }
        .multilineTextAlignment(.leading)
        .navigationTitle(Text("Seed phrase photo verification"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    onRetake()
                } label: {
                    Image(systemName: "chevron.left")
                }
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
