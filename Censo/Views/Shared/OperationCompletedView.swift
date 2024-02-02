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
                
                Image("CongratsFistBump")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal)
                
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
        .navigationBarHidden(true)
        .onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .inactive, .background:
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    onSuccess()
                }
            default:
                break
            }
        }
    }
}

#Preview {
    OperationCompletedView(successText: "Thanks for helping someone keep their crypto safe.\n\nYou may now close the app.") {}.foregroundColor(Color.Censo.primaryForeground)
}
