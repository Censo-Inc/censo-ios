//
//  PhraseSaveSuccess.swift
//  Censo
//
//  Created by Ata Namvari on 2023-10-19.
//

import SwiftUI

struct PhraseSaveSuccess: View {
    var isFirstTime: Bool
    var onFinish: () -> Void
    
    @State private var showPushNotificationSettings = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack(alignment: .top) {
                Image("CenteredCongrats")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                GeometryReader { geometry in
                    Text("Congrats!")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, geometry.size.height * 0.17)
                        .padding(.leading, geometry.size.width * 0.3)
                }
            }.multilineTextAlignment(.center)

            Text("Your seed phrase is securely stored.\n\nIt can be accessed only by you.")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .padding(30)
                .fixedSize(horizontal: false, vertical: true)
            Button() {
                if isFirstTime {
                    showPushNotificationSettings = true
                } else {
                    onFinish()
                }
            } label: {
                Text("OK")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(30)
            .accessibilityIdentifier("okButton")
        }
        .sheet(isPresented: $showPushNotificationSettings, content: {
            PushNotificationSettings {
                showPushNotificationSettings = false
                onFinish()
            }
        })
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .navigationBarBackButtonHidden(true)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    onFinish()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        })
    }
}


#if DEBUG
struct PhraseSaveSuccess_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PhraseSaveSuccess(isFirstTime: true) {}
        }
        .foregroundColor(Color.Censo.primaryForeground)
    }
    
}
#endif
