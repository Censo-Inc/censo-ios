//
//  Login.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-18.
//

import SwiftUI

struct Login: View {
    var onShowLoginIdResetFlow: () -> Void
    var onSuccess: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            Image("CensoLogoDarkBlueStacked")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 124)
            
            Text("The Seed Phrase Manager")
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
            
            AppleSignIn(onSuccess: onSuccess)
                .padding(.top)
            
            Button {
                onShowLoginIdResetFlow()
            } label: {
                Text("Need to reset your Login ID?")
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity)
            }
            
            Spacer()
            VStack {
                HStack(alignment: .bottom) {
                    VStack {
                        Image("EyeSlash")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 40)
                        Text("No personal info\ncollected, ever.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                    VStack {
                        Image("Safe")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 40)
                        Text("Multiple layers of \nauthentication.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Divider()
                    .padding()
                
                LoginBottomLinks()
            }
        }
    }
}

#if DEBUG
struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login(
            onShowLoginIdResetFlow: {},
            onSuccess: {}
        ).foregroundColor(.Censo.primaryForeground)
    }
}
#endif
