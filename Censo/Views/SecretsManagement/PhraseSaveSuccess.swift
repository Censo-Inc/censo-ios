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

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 100)

            if isFirstTime {
                Text("Congratulations!\n\nYou'll never have to worry about losing access to your valuable crypto again.")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(30)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Your seed phrase is securely stored.\n\nIt can be accessed only by you.")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(30)
                
            }
            Spacer()
            Button() {
                onFinish()
            } label: {
                Text("OK")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(30)
        }
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .navigationBarBackButtonHidden(true)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    onFinish()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
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
    }
}
#endif
