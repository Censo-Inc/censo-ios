//
//  ApproverStatus.swift
//  Approver
//
//  Created by Anton Onyshchenko on 05.01.24.
//

import Foundation
import SwiftUI

struct ApproverStatus: View {
    var active: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            if active {
                Image("TwoPeople")
                    .renderingMode(.template)
                    .frame(width: 32, height: 32)
                Text("Active approver")
                    .font(.system(size: 14))
                    .bold()
            } else {
                Image("TwoPeople")
                    .frame(width: 32, height: 32)
                    .opacity(0.2)
                Text("Not an active approver")
                    .font(.system(size: 14))
                    .bold()
            }
        }
    }
}

