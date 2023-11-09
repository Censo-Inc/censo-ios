//
//  GetLiveWithApprover.swift
//  Censo
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI

struct GetLiveWithApprover : View {
    @Environment(\.dismiss) var dismiss
    var approverName: String
    var showResumeLater = true
    var onContinue: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Activate \(approverName)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom)
                
                Text("Activating \(approverName) as an approver will take about 2 minutes. This activation should preferably take place while you’re on the phone or in-person to ensure that you are activating the proper approver.")
                    .font(.subheadline)
                    .padding(.bottom)
                
                Button {
                    onContinue()
                } label: {
                    Text("Activate now")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.bottom)
                
                if showResumeLater {
                    Button {
                        dismiss()
                    } label: {
                        Text("Resume later")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .padding(.bottom)
                }
            }
        }
        .padding([.leading, .trailing], 32)
    }
}

#if DEBUG
#Preview {
    NavigationView {
        GetLiveWithApprover(
            approverName: "Neo",
            onContinue: {}
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                }
            }
        })
    }
}
#endif
