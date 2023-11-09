//
//  PhraseSaveSuccess.swift
//  Censo
//
//  Created by Ata Namvari on 2023-10-19.
//

import SwiftUI

struct PhraseSaveSuccess: View {
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 100)

            Text("Encrypted")
                .font(.title.bold())
            Text("Now can be accessed only by you")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Spacer()
            Button() {
                onFinish()
            } label: {
                Text("Continue")
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
            PhraseSaveSuccess() {}
        }
    }
}
#endif
