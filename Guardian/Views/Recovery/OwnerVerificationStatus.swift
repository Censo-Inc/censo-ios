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
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Status: \(status)")
                        .font(.caption)
                        .foregroundColor(.Censo.lightGray)
                    Text("Owner").bold()
                }
                
                content()
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 5)
            
            Divider()
                .padding(.leading, 2)
        }
        .padding()
        .frame(height: 75)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.Censo.darkBlue, lineWidth: 1)
        }
        .padding(.horizontal)
    }
}

