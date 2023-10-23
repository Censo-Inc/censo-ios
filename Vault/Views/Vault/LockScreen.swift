//
//  LockScreen.swift
//  Vault
//
//  Created by Brendan Flood on 10/20/23.
//

import SwiftUI

struct LockScreen: View {
    
    var onReadyToStartFaceScan: () -> Void

    var body: some View {
        VStack(alignment: .center) {
            Image("LockLaminated")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200)
                .saturation(0.0)
            
            Text("Data encrypted")
                .font(.system(size: 24))
                .padding(.bottom, 1)
                .bold()
                    
            Text("Censo has encrypted your data behind a live 3D scan of your face with layered security")
                .font(.system(size: 14))
                .padding(32)
                                           
            Button {
                onReadyToStartFaceScan()
            } label: {
                HStack {
                    Spacer()
                    Image("FaceScanBW")
                        .resizable()
                        .frame(width: 36, height: 36)
                    Text("Face scan to unlock")
                    Spacer()
                }
            }
            .buttonStyle(RoundedButtonStyle())
            .padding()
            .frame(maxWidth: .infinity)

        }
        .multilineTextAlignment(.center)
    }
}

#if DEBUG
#Preview {
    NavigationView {
        LockScreen(onReadyToStartFaceScan: {})
    }
}
#endif
