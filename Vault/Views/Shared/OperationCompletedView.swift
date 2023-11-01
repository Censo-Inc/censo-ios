//
//  OperationCompletedView.swift
//  Vault
//
//  Created by Brendan Flood on 10/31/23.
//

import SwiftUI

struct OperationCompletedView: View {
    
    var successText: String = "Approved"
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
            HStack {
                Spacer()
                
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.black)
                    .frame(maxWidth: 162, maxHeight: 162)
                
                Spacer()
            }
            
            Text(successText)
                .font(.system(size: 24))
                .bold()
                .padding([.leading, .trailing], 32)
                .padding([.top], 25)
                .padding([.bottom], 10)
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    OperationCompletedView()
}
