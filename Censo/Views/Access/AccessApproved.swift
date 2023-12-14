//
//  AccessApproved.swift
//  Censo
//
//  Created by Anton Onyshchenko on 30.10.23.
//

import Foundation
import SwiftUI

struct AccessApproved : View {
    var body: some View {
        VStack {
            ZStack {
                
                Image("AccessApproved")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .padding(.top)
                
                VStack(alignment: .center) {
                    Spacer()
                    Text("Approved!")
                        .font(.system(size: UIFont.textStyleSize(.largeTitle) * 1.5, weight: .medium))
                    Spacer()
                }
            }
        }
        .frame(maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AccessApproved()
    }.foregroundColor(Color.Censo.primaryForeground)
}
#endif
