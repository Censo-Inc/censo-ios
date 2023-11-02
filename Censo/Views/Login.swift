//
//  Login.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-18.
//

import SwiftUI

struct Login: View {
    var onSuccess: () -> Void

    var body: some View {
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
                
                Text("Seed Phrase Manager")
                    .font(.system(size: 24, weight: .semibold))
                    .padding()
                
                AppleSignIn(onSuccess: onSuccess)

                Spacer()
                VStack {
                    HStack(alignment: .top) {
                        VStack {
                            Image("EyeSlash")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            Text("No personal info collected, ever.")
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

    }
}

#if DEBUG
struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login() {}
    }
}
#endif
