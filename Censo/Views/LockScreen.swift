//
//  LockScreen.swift
//  Censo
//
//  Created by Brendan Flood on 10/20/23.
//

import SwiftUI

struct LockScreen: View {
    
    var onReadyToAuthenticate: () -> Void

    var body: some View {
        VStack(alignment: .center) {
            Image("LockLaminated")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200)
                .saturation(0.0)
            
            Text("Locked")
                .font(.system(size: 24))
                .padding(.bottom, 1)
                .bold()

            Button {
                onReadyToAuthenticate()
            } label: {
                HStack {
                    Spacer()
                    Image("FaceScanBW")
                        .resizable()
                        .frame(width: 36, height: 36)
                    Text("Unlock")
                        .font(.system(size: 24, weight: .semibold))
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
        LockScreen(onReadyToAuthenticate: {})
    }
}
#endif
