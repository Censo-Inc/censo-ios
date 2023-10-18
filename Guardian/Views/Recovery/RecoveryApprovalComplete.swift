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
            
            Text("Access Approved!")
                            .font(.title.bold())
                            .padding()
        }
        .multilineTextAlignment(.center)
    }
}

#if DEBUG

#Preview {
    RecoveryApprovalComplete(onSuccess: {})
}

#endif
