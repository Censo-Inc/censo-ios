//
//  LearnMore.swift
//  Censo
//
//  Created by Ben Holzman on 1/12/24.
//

import SwiftUI

struct LearnMore<Content>: View where Content: View {
    var title: String
    @Binding var showLearnMore: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        NavigationView {
            VStack {
                Text(title)
                    .font(.largeTitle)
                    .padding([.horizontal, .top])
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                LearnMoreDivider()
                ScrollView {
                    content().padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showLearnMore = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            })
        }
    }
}

struct LearnMoreDivider: View {
    var body: some View {
        Color.Censo.aquaBlue
            .frame(width: 50, height: 4)
    }
}

#if DEBUG
#Preview {
    LearnMore(title: "Title", showLearnMore: .constant(true)) {
        VStack(alignment: .leading) {
            Text("Contents asdf")
                .padding()
            Text("Paragraph two")
                .padding()
        }
    }
}
#endif
