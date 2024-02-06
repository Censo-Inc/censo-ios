//
//  CapturePhrasePhoto.swift
//  Censo
//
//  Created by Brendan Flood on 1/18/24.
//

import SwiftUI

struct PhotoPhrase: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var showingSave = false
    @State private var imageData: Data = Data()
    
    var ownerState: API.OwnerState.Ready
    var isFirstTime: Bool
    var onBack: () -> Void
    
    var body: some View {
        NavigationStack {
            PhotoCapture(onBack: onBack) { uiImage, retakeClosure in
                SeedPhotoVerification(
                    imageData: uiImage.jpegData(compressionQuality: 0.8)!,
                    onSubmit: { imageData in
                        self.imageData = imageData
                        showingSave = true
                    },
                    onRetake: retakeClosure
                )
            }
            .frame(maxWidth: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $showingSave) {
                SaveSeedPhrase(
                    seedPhrase: .image(imageData: imageData),
                    ownerState: ownerState,
                    isFirstTime: isFirstTime,
                    onSuccess: {
                        showingSave = false
                        dismiss()
                    }
                )
            }
        }
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        PhotoPhrase(
            ownerState: .sample,
            isFirstTime: true,
            onBack: {}
        )
    }
}
#endif
