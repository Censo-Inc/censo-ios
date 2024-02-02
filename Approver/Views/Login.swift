//
//  Login.swift
//  Censo
//
//  Created by Brendan Flood on 10/31/23.
//

import SwiftUI

struct Login: View {
    var onSuccess: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack {
                Image("Entrance")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                HStack {
                    Image("CensoText")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 104)
                        .padding([.top], 8)
                    
                    Text("approver")
                        .font(.system(size: 36, weight: .light))
                        .padding(.leading, 5)
                }
            }

            Spacer()
            
            VStack(alignment: .leading, spacing: 0) {
                Text("To continue, you need to Sign in with Apple.")
                    .font(.subheadline)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            
            VStack {
                AppleSignIn(onSuccess: onSuccess)
                
                Text("By tapping Sign in, you agree to our terms of use.")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.vertical)
                
                Divider()
                    .padding([.horizontal])
                
                LoginBottomLinks()
            }
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

