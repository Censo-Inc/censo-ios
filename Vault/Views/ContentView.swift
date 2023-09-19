//
//  ContentView.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Authentication { deviceKey in
            OwnerSetup()
        }
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
