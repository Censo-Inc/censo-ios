//
//  GetLiveWithBeneficiary.swift
//  Approver
//
//  Created by Brendan Flood on 2/14/24.
//

import SwiftUI
import Moya

struct GetLiveWithBeneficiary: View {
    @Environment(\.dismiss) var dismiss
    
    var onContinue: () -> Void
    var onBack: (() -> Void)?
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Spacer()

                Text("Approve request")
                    .font(.title3)
                    .bold()
                    .padding(.vertical)
                
                Text("Approving a request will take about 2 minutes. This approval should preferably take place while you’re on the phone or in-person to ensure that you are assisting the proper individual.\n\nIn the next step you will verify identity of the beneficiary for the person you have been assisting before approving the request.")
                    .font(.body)
                
                Spacer()
                
                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
            }
            .padding(.vertical)
            .padding(.horizontal, 32)
        }
        .navigationInlineTitle("")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                if let onBack {
                    DismissButton(icon: .back) {
                        onBack()
                    }
                } else {
                    DismissButton(icon: .close)
                }
            }
        })
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        GetLiveWithBeneficiary(onContinue: {})
            .foregroundColor(.Censo.primaryForeground)
    }
}
#endif
