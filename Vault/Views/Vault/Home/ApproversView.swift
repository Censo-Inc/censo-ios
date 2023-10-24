//
//  ApproversView.swift
//  Vault
//
//  Created by Brendan Flood on 10/23/23.
//

import SwiftUI

struct ApproversView: View {
    var body: some View {
        VStack {
            VStack {
                Spacer()
                Text("Approvers")
            }
            
            Divider()
            .padding([.bottom], 4)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

#if DEBUG
#Preview {
    ApproversView()
}
#endif
