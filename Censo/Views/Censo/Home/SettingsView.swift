//
//  SettingsView.swift
//  Censo
//
//  Created by Brendan Flood on 10/23/23.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var showingError = false
    @State private var error: Error?
    @State private var resetRequested = false
    @State private var resetInProgress = false
    
    var body: some View {
        VStack {
            VStack {
                Spacer()
                Button {
                    resetRequested = true
                } label: {
                    if resetInProgress {
                        ProgressView()
                    } else {
                        HStack {
                            Spacer()
                            Image("arrow.circlepath")
                                .frame(width: 36, height: 36)
                            Text("Reset User Data")
                                .font(.system(size: 24, weight: .semibold))
                                .padding()
                            Spacer()
                        }.frame(maxWidth: 322)
                    }
                }
                .buttonStyle(RoundedButtonStyle())
            }
            
            Divider()
            .padding([.bottom], 4)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button {
                showingError = false
                error = nil
            } label: { Text("OK") }
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert("Reset User", isPresented: $resetRequested) {
            Button {
                deleteUser()
            } label: { Text("Confirm") }
            Button {
            } label: { Text("Cancel") }
        } message: {
            Text("You are about to delete your user and associated data. This action cannot be reversed. \nAre you sure?")
        }
    }
    
    private func deleteUser() {
        resetInProgress = true
        apiProvider.request(with: session, endpoint: .deleteUser) { result in
            resetInProgress = false
            switch result {
            case .success:
                onOwnerStateUpdated(.initial)
            case .failure(let error):
                self.showingError = true
                self.error = error
            }
        }
    }
}

#if DEBUG
#Preview {
    SettingsView(session: .sample, onOwnerStateUpdated: {_ in })
}
#endif
