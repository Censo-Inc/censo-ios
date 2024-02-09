//
//  GetLive.swift
//  Censo
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI

struct GetLive : View {
    @Environment(\.dismiss) var dismiss
    var name: String
    var isApprover: Bool = true
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
                        Text("Verifying \(name) as \(isApprover ? "an approver" : "a beneficiary") will take about 2 minutes. This verification should preferably take place while you’re on the phone or in-person to ensure that you are verifying the proper \(isApprover ? "approver" : "person").")
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.subheadline)
                            .padding(.bottom)
                        
                        Button {
                            onContinue()
                        } label: {
                            Text("Verify now")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RoundedButtonStyle())
                        .padding(.vertical)
                        
                        if showResumeLater {
                            Button {
                                dismiss()
                            } label: {
                                Text("Resume later")
                                    .font(.headline)
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
        .navigationTitle(isApprover ? "Verify \(name)" : "Add Beneficiary")
    }
}

#if DEBUG
#Preview("Approver") {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            GetLive(
                name: "Neo",
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

#Preview("Beneficiary") {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            GetLive(
                name: "Ben Eficiary",
                isApprover: false,
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
