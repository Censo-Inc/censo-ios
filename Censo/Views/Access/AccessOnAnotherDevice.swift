//
//  AccessOnAnotherDevice.swift
//  Censo
//
//  Created by Brendan Flood on 11/30/23.
//

import SwiftUI


struct AccessOnAnotherDevice: View {

    var onCancelAccess: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                Text("Access was requested on another device")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                
                Text("For security reasons, we allow access only from the same device")
                    .font(.headline)
                    .fontWeight(.medium)
                    .padding()
                
                Button {
                    onCancelAccess()
                } label: {
                    Text("Cancel access")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding()
                
            }
            .padding()
            Spacer()
        }
    }
}

#if DEBUG

#Preview {
    NavigationView {
        AccessOnAnotherDevice(
            onCancelAccess: {}
        )
    }
}
#endif
