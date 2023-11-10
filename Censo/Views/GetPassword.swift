//
//  GetPassword.swift
//  Censo
//
//  Created by Ben Holzman on 11/15/23.
//

import SwiftUI

struct GetPassword: View {
    var onGetPassword: (Base64EncodedString) -> Void

    @State private var password = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Text("Enter your password")
                .font(.title2.bold())
                .padding()
            SecureField("Enter your password...", text: $password) {
               returnPassword()
            }
            .textFieldStyle(RoundedTextFieldStyle())
            .padding()
        
            Button {
                if let cryptedPassword = pbkdf2(password: password) {
                    returnPassword()
                }
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding()
        }
        .padding()
    }
    
    private func returnPassword() {
        if let cryptedPassword = pbkdf2(password: password) {
            onGetPassword(Base64EncodedString(data: cryptedPassword))
        }
    }
}

#if DEBUG
#Preview {
    GetPassword { _ in }
}
#endif
