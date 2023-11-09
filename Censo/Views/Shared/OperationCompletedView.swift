//
//  OperationCompletedView.swift
//  Censo
//
//  Created by Brendan Flood on 10/31/23.
//

import SwiftUI

struct OperationCompletedView: View {
    @Environment(\.scenePhase) var scenePhase
    var successText: String = "Approved"
    var onSuccess: () -> Void
    
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
                .font(.title2)
                .bold()
                .padding()
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .inactive, .background:
                onSuccess()
            default:
                break
            }
        }
    }
}

#Preview {
    OperationCompletedView(successText: "Congratulations. You're all done!\n\nThanks for helping someone keep their crypto safe.\n\nYou may now close the app.") {}
}
