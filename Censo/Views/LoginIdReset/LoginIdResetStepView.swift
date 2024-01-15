//
//  LoginIdResetStepView.swift
//  Censo
//
//  Created by Anton Onyshchenko on 10.01.24.
//

import Foundation
import SwiftUI


struct LoginIdResetStepView<IconContent, Content>: View where IconContent : View, Content : View {
    var isLast: Bool = false
    @ViewBuilder var icon: () -> IconContent
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack {
                icon()
                
                if !isLast {
                    Rectangle()
                        .fill(Color.Censo.darkBlue)
                        .frame(maxWidth: 3, maxHeight: .infinity)
                }
            }
            .padding(.trailing)
            
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }
}

