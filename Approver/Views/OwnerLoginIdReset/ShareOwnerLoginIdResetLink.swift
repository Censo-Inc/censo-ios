//
//  ShareOwnerLoginIdResetLink.swift
//  Approver
//
//  Created by Anton Onyshchenko on 05.01.24.
//

import Foundation
import SwiftUI


struct ShareOwnerLoginIdResetLink: View {
    @Environment(\.dismiss) var dismiss
    var link: URL
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Please send the login recovery link back to the person that has contacted you.")
                .font(.title3)
                .padding(.vertical)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            ShareLink(
                item: link
            ) {
                HStack(spacing: 0) {
                    Spacer()
                    Image("Export")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 28, height: 28)
                        .padding(.horizontal, 10)
                        .foregroundColor(Color.Censo.buttonTextColor)
                        .bold()
                    Text("Share")
                        .font(.title2)
                        .foregroundColor(Color.Censo.buttonTextColor)
                        .padding(.trailing)
                    Spacer()
                }
            }
            .buttonStyle(RoundedButtonStyle())
        }
        .padding(.horizontal, 32)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    @State var user = API.ApproverUser(approverStates: [
        .init(
            participantId: .random(),
            phase: .complete,
            ownerLabel: "Anton"
        )
    ])
    
    return NavigationView {
        ShareOwnerLoginIdResetLink(link: URL(string: "censo-reset://token/XXX")!)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text("Login assistance"))
            .navigationBarBackButtonHidden(true)
    }
    .foregroundColor(.Censo.primaryForeground)
}
#endif
