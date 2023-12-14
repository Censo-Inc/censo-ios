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
                Image("CensoLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 124)
                
                Text("The Seed Phrase Manager")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                
                AppleSignIn(onSuccess: onSuccess)

                Spacer()
                VStack {
                    HStack(alignment: .top) {
                        VStack {
                            Image("EyeSlash")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            Text("No personal info\ncollected, ever.")
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        VStack {
                            Image("Safe")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            Text("Multiple layers of \nauthentication.")
                                .font(.footnote)
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
        Login() {}.foregroundColor(.Censo.primaryForeground)
    }
}
#endif
