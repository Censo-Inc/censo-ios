//
//  Login.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-18.
//

import SwiftUI

struct Login: View {
    @AppStorage("acceptedTermsOfUseVersion") var acceptedTermsOfUseVersion: String = ""

    var onSuccess: () -> Void

    var body: some View {
        if (acceptedTermsOfUseVersion != "") {
            VStack {
                Spacer()
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 124)
                
                Image("CensoText")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 208)
                
                Text("sensible crypto security")
                    .font(.system(size: 24, weight: .semibold))
                    .padding()
                
                AppleSignIn(onSuccess: onSuccess)
                
                HStack {
                    Image(systemName: "info.circle")
                    Text("Why Apple ID?")
                        .font(.system(size: 18, weight: .medium))
                }
                Spacer()
                VStack {
                    HStack(alignment: .top) {
                        VStack {
                            Image("EyeSlash")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            Text("No personal info required, ever.")
                                .font(.system(size: 14))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        VStack {
                            Image("Safe")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            Text("Multiple layers of authentication.")
                                .font(.system(size: 14))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Divider()
                        .padding()
                    
                    LoginBottomLinks()
                    
                }.frame(height: 180)
            }
        } else {
            TermsOfUse(
                text: TermsOfUse.v0_1,
                onAccept: {
                    acceptedTermsOfUseVersion = "v0.1"
                }
            )
        }
    }
}

#if DEBUG
struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login() {}
    }
}
#endif
