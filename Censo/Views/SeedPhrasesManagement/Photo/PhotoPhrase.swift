//
//  CapturePhrasePhoto.swift
//  Censo
//
//  Created by Brendan Flood on 1/18/24.
//

import SwiftUI

struct PhotoPhrase: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    @State private var showingSave = false
    @State private var imageData: Data = Data()
    
    var onComplete: (API.OwnerState) -> Void
    var onBack: () -> Void
    var session: Session
    var ownerState: API.OwnerState.Ready
    var isFirstTime: Bool
    
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
            .padding()
            .frame(maxWidth: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $showingSave) {
                SaveSeedPhrase(
                    seedPhrase: .image(imageData: imageData),
                    session: session,
                    ownerState: ownerState,
                    isFirstTime: isFirstTime,
                    onSuccess: { ownerState in
                        showingSave = false
                        onComplete(ownerState)
                        dismiss()
                    }
                )
            }
        }
    }
}

#if DEBUG
#Preview {
    PhotoPhrase(
        onComplete: {_ in},
        onBack: {},
        session: .sample,
        ownerState: .sample,
        isFirstTime: true
    )
    .foregroundColor(Color.Censo.primaryForeground)
}
#endif
