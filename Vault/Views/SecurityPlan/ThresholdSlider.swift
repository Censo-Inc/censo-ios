//
//  ThresholdSlider.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-26.
//

import SwiftUI

struct ThresholdSlider: View {
    @Binding var threshold: Int

    var totalApprovers: Int

    private var floatThreshold: Binding<Float> {
        Binding {
            Float(threshold)
        } set: { newValue in
            threshold = Int(newValue)
        }
    }

    var body: some View {
        VStack {
            HStack {
                ForEach(1...totalApprovers, id: \.self) { i in
                    Image(systemName: "iphone")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15)
                        .overlay {
                            if i <= Int(threshold) {
                                Image(systemName: "checkmark")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 7)
                            }
                        }

                    if i != totalApprovers {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 5)

            Slider(value: floatThreshold, in: 1...Float(totalApprovers), step: 1)
                .tint(.Censo.darkBlue)

            HStack {
                ForEach(1...totalApprovers, id: \.self) { i in
                    Text("\(i)")
                        .font(.caption.bold())

                    if i != totalApprovers {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 10)
        }
        .padding(.horizontal, 25)
    }
}
