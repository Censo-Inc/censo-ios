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
    var showFistBump: Bool = true
    var onSuccess: () -> Void
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
            if showFistBump {
                HStack {
                    Spacer()
                    
                    Image("CongratsFistBump")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal)
                    
                    Spacer()
                }
            } else {
                Text("Approved")
                    .font(.largeTitle)
                    .bold()
                    .padding()
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

#if DEBUG
#Preview {
    OperationCompletedView(successText: "Thanks for helping someone keep their crypto safe.\n\nYou may now close the app.") {}.foregroundColor(Color.Censo.primaryForeground)
}

#Preview("noFistBump") {
    OperationCompletedView(successText: "Thanks for helping someone keep their crypto safe.\n\nYou may now close the app.", showFistBump: false) {}.foregroundColor(Color.Censo.primaryForeground)
}
#endif
