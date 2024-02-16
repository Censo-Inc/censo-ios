//
//  View+Alert.swift
//  Censo
//
//  Created by Brendan Flood on 2/15/24.
//

import SwiftUI


struct Alert: ViewModifier {
    var isPresented: Binding<Bool>
    var error: Error?
    var onOk: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: isPresented, presenting: error) { _ in
                Button {
                    onOk?()
                } label: { Text("OK") }
            } message: { error in
                Text(error.localizedDescription)
            }
    }
}

extension View {
    func errorAlert(isPresented: Binding<Bool>, presenting: Error?, onOk: (() -> Void)? = nil) -> some View {
        modifier(Alert(isPresented: isPresented, error: presenting, onOk: onOk))
    }
}

#if DEBUG
#Preview {
    Text("Some Text")
        .errorAlert(isPresented: .constant(true), presenting: CensoError.cannotCreateTotpSecret)
}

#endif

