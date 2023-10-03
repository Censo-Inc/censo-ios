//
//  PinInputField.swift
//  Vault
//
//  Created by Ata Namvari on 2023-10-01.
//

import SwiftUI

struct PinInputField: UIViewRepresentable {
    @Binding var value: [Int]

    var length: Int
    var foregroundColor: Color = .Censo.darkBlue
    var unfocusedColor: Color = .gray.opacity(0.5)

    func makeUIView(context: Context) -> PinInput {
        let pinInput = PinInput(length: length)
        pinInput.setContentHuggingPriority(.defaultHigh, for: .vertical)
        pinInput.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        pinInput.addTarget(context.coordinator, action: #selector(Coordinator.didChangeValue(_:)), for: .valueChanged)
        return pinInput
    }

    func updateUIView(_ uiView: PinInput, context: Context) {
        uiView.tintColor = UIColor(foregroundColor)
        uiView.unfocusedColor = UIColor(unfocusedColor)
        uiView.value = value
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(value: _value)
    }

    class Coordinator {
        @Binding var value: [Int]

        init(value: Binding<[Int]>) {
            self._value = value
        }

        @objc
        func didChangeValue(_ sender: PinInput) {
            value = sender.value
        }
    }
}

#if DEBUG
struct PinInputField_Previews: PreviewProvider {
    struct PinPreview: View {
        @State private var pin: [Int] = []

        var body: some View {
            VStack {
                PinInputField(value: $pin, length: 6)

                Text("Entered: \(pin.map(String.init).joined())")
            }
            .padding()
        }
    }

    static var previews: some View {
        PinPreview()
    }
}
#endif
