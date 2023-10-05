//
//  OwnerVerifcationStatus.swift
//  Recovery
//
//  Created by Brendan Flood on 10/3/23.
//

import SwiftUI

struct OwnerVerificationStatus<Content>: View where Content : View {
    var status: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Status: \(status)")
                        .font(.caption)
                        .foregroundColor(.Censo.lightGray)
                    Text("Owner").bold()
                }
                Spacer()
                
                content()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            
            Divider()
                .padding(.leading, 20)
        }
    }
}

