//
//  BeginFaceScanButton.swift
//  Censo
//
//  Created by Anton Onyshchenko on 29.01.24.
//

import Foundation
import SwiftUI

struct BeginFaceScanButton : View {
    var action: () -> Void
    
    var body: some View {
        Text("By tapping Begin face scan, I consent to the collection and processing of a scan of my face for the purposes of authentication in connection with my use of the Censo App.")
            .font(.caption)
            .italic()
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom)
        
        Button {
            action()
        } label: {
            HStack {
                Spacer()
                Image("FaceScanBW")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 36, height: 36)
                Text("Begin face scan")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
        }
        .buttonStyle(RoundedButtonStyle())
        .frame(maxWidth: .infinity)
    }
}
