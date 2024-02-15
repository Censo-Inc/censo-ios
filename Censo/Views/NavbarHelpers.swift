//
//  NavbarHelpers.swift
//  Censo
//
//  Created by Anton Onyshchenko on 09.02.24.
//

import Foundation
import SwiftUI

struct DismissButton : View {
    @Environment(\.dismiss) var dismiss
    
    enum Icon {
        case back
        case close
    }
    
    var icon: Icon
    var action: (() -> Void)?
    
    var body: some View {
        Button {
            if let action = action {
                action()
            } else {
                dismiss()
            }
        } label: {
            switch (icon) {
            case .back:
                Image(systemName: "chevron.left")
            case .close:
                Image(systemName: "xmark")
            }
        }
    }
}

struct NavigationInlineTitle: ViewModifier {
    var title: String
    var hideBackButton: Bool
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(hideBackButton)
    }
}

extension View {
    func navigationInlineTitle(_ title: String, hideBackButton: Bool = true) -> some View {
        modifier(NavigationInlineTitle(title: title, hideBackButton: hideBackButton))
    }
}
