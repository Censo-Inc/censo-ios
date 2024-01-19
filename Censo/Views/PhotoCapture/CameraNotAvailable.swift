//
//  CameraNotAvailable.swift
//  Censo
//
//  Created by Brendan Flood on 1/18/24.
//

import SwiftUI

struct CameraNotAvailable: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("Unable to Access Camera")
                .font(.title2)
                .fontWeight(.semibold)
            

            Text("Grant Censo access to your camera in order to take your photo.")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)


            Text("In your Settings App, go to Privacy > Camera and verify the switch next to Camera is on to continue.")
                .multilineTextAlignment(.center)
                .font(.footnote)
            

            Button(action: {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }) {
                Text("Open Settings App")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            
            Spacer()
            
        }
        .padding(.horizontal, 32)
    }
}

#if DEBUG
#Preview {
    CameraNotAvailable().foregroundColor(Color.Censo.primaryForeground)
}
#endif
