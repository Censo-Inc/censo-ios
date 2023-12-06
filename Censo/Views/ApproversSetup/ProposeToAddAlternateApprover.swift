//
//  ProposeToAddAlternateApprover.swift
//  Censo
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI

struct ProposeToAddAlternateApprover : View {
    @Environment(\.dismiss) var dismiss
    
    var onAccept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("Invite a second approver")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom)
            
            Text("""
                 Adding a **second approver** ensures access to your seed phrase even if your first approver is unavailable. It also ensures that you can access your seed phrase in the event you lose your own Apple ID or your biometry fails.
                 """)
                .font(.subheadline)
                .padding(.bottom)
            
            Button {
                onAccept()
            } label: {
                Text("Invite a second")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(.vertical)
        }
        .padding([.leading, .trailing], 32)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                }
            }
        })
    }
}

#if DEBUG
#Preview {
    ProposeToAddAlternateApprover(
        onAccept: {}
    )
}
#endif
