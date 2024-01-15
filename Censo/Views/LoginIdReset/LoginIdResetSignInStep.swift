//
//  LoginIdResetSignInStep.swift
//  Censo
//
//  Created by Anton Onyshchenko on 10.01.24.
//

import Foundation
import SwiftUI

struct LoginIdResetSignInStep: View {
    var enabled: Bool
    var onSuccess: () -> Void
    
    var body: some View {
        LoginIdResetStepView(
            icon: {
                Image(systemName: "apple.logo")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(5)
                    .frame(width: 64, height: 64)
                    .foregroundColor(.Censo.darkBlue)
            },
            content: {
                Text("2. Sign in with new Apple ID")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.bottom)
                
                Text("Sign in with the new Apple ID you wish to associate with Censo.")
                    .font(.body)
                    .fontWeight(.regular)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom)
                
                AppleSignIn(
                    enabled: enabled,
                    onSuccess: onSuccess
                )
                .frame(height: 58)
                .padding(.horizontal)
            }
        )
    }
}

