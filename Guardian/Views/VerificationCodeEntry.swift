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
    
    var body: some View {
        PinInputField(value: $pinInput, length: 6)
            .padding()
    }
}
