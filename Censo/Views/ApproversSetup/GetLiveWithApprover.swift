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
        GeometryReader { geometry in
            ZStack {
                VStack {
                    Image("ActivateApprover")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            maxWidth: geometry.size.width,
                            maxHeight: geometry.size.height * 0.6
                        )
                    Spacer()
                }
                VStack(alignment: .leading) {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Verifying \(approverName) as an approver will take about 2 minutes. This verification should preferably take place while you’re on the phone or in-person to ensure that you are verifying the proper approver.")
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.subheadline)
                            .padding(.bottom)
                        
                        Button {
                            onContinue()
                        } label: {
                            Text("Verify now")
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
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Verify \(approverName)")
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            GetLiveWithApprover(
                approverName: "Neo",
                onContinue: {}
            )
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            })
        }
    }
}
#endif
