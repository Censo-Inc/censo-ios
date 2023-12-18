//
//  ContentView.swift
//  Censo
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI
import Moya

struct ContentView: View {
    var body: some View {
        Authentication(
            loggedOutContent: { onSuccess in
                Login(onSuccess: onSuccess)
            }, 
            loggedInContent: { session in
                CloudCheck {
                    AppAttest(session: session) {
                        LoggedInOwnerView(session: session)
                    }
                }
            }
        )
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension CommandLine {
    static var isTesting: Bool = {
        arguments.contains("testing")
    }()
}
#endif
