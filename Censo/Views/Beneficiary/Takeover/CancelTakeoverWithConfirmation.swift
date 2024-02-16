//
//  CancelTakeoverConfirmation.swift
//  Censo
//
//  Created by Brendan Flood on 2/15/24.
//

import SwiftUI

struct CancelTakeoverWithConfirmation: ViewModifier {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var isPresented: Binding<Bool>
    var onError: (Error) -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("Cancel takeover", isPresented: isPresented) {
                Button("No", role: .cancel) {}
                Button("Yes", role: .destructive) {
                    cancelTakeover(ownerRepository, ownerStateStoreController, onError)
                }
            } message: {
                Text("You are about cancel this takeover. You will need to start over again if you confirm. Are you sure?")
            }
    }
}

extension View {
    func cancelTakeoverWithConfirmation(isPresented: Binding<Bool>, onError: @escaping (Error) -> Void) -> some View {
        modifier(CancelTakeoverWithConfirmation(isPresented: isPresented, onError: onError))
    }
}

