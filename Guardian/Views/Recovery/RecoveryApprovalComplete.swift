//
//  RecoveryComplete.swift
//  Recovery
//
//  Created by Brendan Flood on 10/3/23.
//

import SwiftUI

struct RecoveryApprovalComplete: View {
    
    var onSuccess: () -> Void
    
    var body: some View {
        NavigationStack {
            
            Text("Recovery Completed")
                            .font(.title.bold())
                            .padding()
            
            InfoBoard {
                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
            }
            .padding()
            
            Spacer()
            
            Button {
                onSuccess()
            } label: {
                Text("Continue")
            }
            .padding()
            .buttonStyle(FilledButtonStyle())
        }
        .multilineTextAlignment(.center)
    }
}

#if DEBUG

#Preview {
    RecoveryApprovalComplete(onSuccess: {})
}

#endif
