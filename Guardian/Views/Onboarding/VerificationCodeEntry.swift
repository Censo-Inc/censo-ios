//
//  VerificationCodeEntry.swift
//  Guardian
//
//  Created by Anton Onyshchenko on 05.10.23.
//

import Foundation
import SwiftUI

struct VerificationCodeEntry: View {
    @Binding var pinInput: [Int]
    var disabled: Bool = false
    
    var body: some View {
        PinInputFieldWithBackground(value: $pinInput, length: 6, disabled: disabled)
            .padding()
    }
}
