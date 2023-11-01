//
//  PhraseSaveSuccess.swift
//  Censo
//
//  Created by Ata Namvari on 2023-10-19.
//

import SwiftUI

struct PhraseSaveSuccess: View {
    var label: String
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 100)

            Text("Saved & encrypted")
                .font(.title.bold())

            Text(label)
                .font(.title2)
        }
        .navigationTitle(Text("Add Seed Phrase"))
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
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
        .onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                onFinish()
            }
        })
    }
}

#if DEBUG
struct PhraseSaveSuccess_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PhraseSaveSuccess(label: "My Seed Phrase") {}
        }
    }
}
#endif
