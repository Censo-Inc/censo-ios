//
//  GetPassword.swift
//  Censo
//
//  Created by Ben Holzman on 11/15/23.
//

import SwiftUI

struct GetPassword: View {
    var onGetPassword: (Base64EncodedString, @escaping (Bool) -> Void) -> Void

    @State private var password = ""
    @State private var invalidPassword = false
    @State private var disableContinue = false
    
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

            if invalidPassword {
                Text("Password was invalid")
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
            }

            Divider()

            Button {
                returnPassword()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding()
            .disabled(disableContinue)
        }
        .padding()
    }
    
    private func returnPassword() {
        disableContinue = true
        if let cryptedPassword = pbkdf2(password: password) {
            onGetPassword(Base64EncodedString(data: cryptedPassword)) { valid in
                invalidPassword = !valid
                disableContinue = false
            }
        } else {
            disableContinue = false
        }
    }
}

#if DEBUG
#Preview {
    GetPassword { _, _ in }
}
#endif
