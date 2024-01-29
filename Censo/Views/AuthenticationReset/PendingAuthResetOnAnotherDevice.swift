//
//  PendingAuthResetOnAnotherDevice.swift
//  Censo
//
//  Created by Anton Onyshchenko on 25.01.24.
//

import SwiftUI

struct PendingAuthResetOnAnotherDevice: View {
    var authType: API.AuthType
    var onCancelReset: () -> Void
    
    var body: some View {
        let resetType = authType == .facetec ? "Biometry" : "Password"
        
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                Text("\(resetType) reset was requested on another device")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                
                Text("For security reasons, we allow to continue only from the same device")
                    .font(.headline)
                    .fontWeight(.medium)
                    .padding()
                
                Button {
                    onCancelReset()
                } label: {
                    Text("Cancel \(resetType.lowercased()) reset")
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
        PendingAuthResetOnAnotherDevice(
            authType: .facetec,
            onCancelReset: {}
        )
    }
}
#endif
