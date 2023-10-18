//
//  Invitation.swift
//  Guardian
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI

enum  GuardianRoute {
    case initial
    case onboard
    case recovery
    case unknown
}


struct GuardianHome: View {

    var body: some View {
        VStack(alignment: .center) {
            Text("This application can only be used by invitation. Please click the invite link you received from the seed phrase owner")
                .font(.title2)
                .padding()
        }
        .multilineTextAlignment(.center)
    }
}

#if DEBUG
struct GuardianHome_Previews: PreviewProvider {
    static var previews: some View {
        GuardianHome()
    }
}
#endif
