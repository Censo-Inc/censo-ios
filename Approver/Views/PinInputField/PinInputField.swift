//
//  PinInputField.swift
//  Censo
//
//  Created by Ata Namvari on 2023-10-01.
//

import SwiftUI

struct PinInputField: UIViewRepresentable {
    @Binding var value: [Int]

    var length: Int
    var foregroundColor: Color = .black
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

struct PinInputFieldWithBackground : View {
    @Binding var value: [Int]

    var length: Int
    var foregroundColor: Color = .black
    var unfocusedColor: Color = .gray.opacity(0.5)
    var disabled: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16.0)
                .strokeBorder(Color.gray, lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 16.0).fill(Color.Censo.gray95))
            
            PinInputField(value: $value, length: 6)
                .padding(.vertical, 34)
                .padding(.horizontal, 20)
                .disabled(disabled)
            
        }
        .frame(height: 100)

    }
}

#if DEBUG
struct PinInputField_Previews: PreviewProvider {
    struct PinPreview: View {
        @State private var pin: [Int] = [4, 2, 8]

        var body: some View {
            VStack {
                PinInputFieldWithBackground(value: $pin, length: 6)
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
