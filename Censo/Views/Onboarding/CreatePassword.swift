//
//  CreatePassword.swift
//  Censo
//
//  Created by Ben Holzman on 11/15/23.
//

import SwiftUI

struct CreatePassword: View {
    var onCreated: (Base64EncodedString) -> Void
    @State private var password = ""
    @State private var passwordAgain = ""
    @State private var createDisabled = true
    @State private var passwordError = " "
    @FocusState private var focusPasswordAgain
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Text("Instead of a face scan, you can secure your seed phrases with a password. You must be sure to save this password as you will need it to access your seed phrases in the future.\n\n\n\nFor security, this password must be at least 30 characters long and contain a mix of letters, numbers, and symbols.")
                .fixedSize(horizontal: false, vertical: true)
                .padding()
            
            Text(passwordError)
                .font(.caption.bold())
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            SecureField("Enter a password...", text: $password) {
                checkPassword()
            }
            .textFieldStyle(RoundedTextFieldStyle())
            .padding([.leading, .trailing, .bottom])
            .accessibilityIdentifier("passwordField")
            
            SecureField("Enter it again...", text: $passwordAgain) {
                checkPasswordAgain()
            }
            .textFieldStyle(RoundedTextFieldStyle())
            .focused($focusPasswordAgain)
            .padding()
            .accessibilityIdentifier("passwordConfirmField")
            
            Button {
                if let cryptedPassword = pbkdf2(password: password) {
                    onCreated(Base64EncodedString(data: cryptedPassword))
                } else {
                    passwordError = "Could not create password, try again"
                }
            } label: {
                Text("Create password")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding()
            .disabled(createDisabled)
            .accessibilityIdentifier("createPasswordButton")
            
            Spacer()
        }
        .padding()
    }
    
    private func checkPassword() {
        if (password.count < 30) {
            passwordError = "Password must be at least 30 characters long"
        } else {
            var missing: [String] = []
            if !password.contains(/[0-9]/) {
                missing.append("numbers")
            }
            if !password.contains(/[a-zA-Z]/) {
                missing.append("letters")
            }
            if !password.contains(/[^0-9a-zA-Z]/) {
                missing.append("symbols")
            }
            if missing.count > 0 {
                passwordError = "Password is missing: \(missing.joined(separator: ", "))"
            } else {
                passwordError = " "
                focusPasswordAgain = true
            }
        }
    }
    
    private func checkPasswordAgain() {
        if (password == passwordAgain) {
            passwordError = " "
            createDisabled = false
        } else {
            passwordError = "Passwords must match"
        }
    }
    
}

#if DEBUG
#Preview {
    CreatePassword { _ in }
}
#endif
