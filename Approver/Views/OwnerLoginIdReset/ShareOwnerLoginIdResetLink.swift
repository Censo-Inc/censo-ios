//
//  ShareOwnerLoginIdResetLink.swift
//  Approver
//
//  Created by Anton Onyshchenko on 05.01.24.
//

import Foundation
import SwiftUI


struct ShareOwnerLoginIdResetLink: View {
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
                        .frame(width: 24, height: 24)
                        .padding(.horizontal, 6)
                        .foregroundColor(Color.Censo.buttonTextColor)
                        .bold()
                    Text("Share")
                        .font(.headline)
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
                DismissButton(icon: .close)
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
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text("Login assistance"))
            .navigationBarBackButtonHidden(true)
    }
    .foregroundColor(.Censo.primaryForeground)
}
#endif
