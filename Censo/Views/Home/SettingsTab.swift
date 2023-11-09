//
//  SettingsTab.swift
//
//  Created by Brendan Flood on 10/23/23.
//

import SwiftUI
import Moya

struct SettingsTab: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var showingError = false
    @State private var error: Error?
    @State private var resetRequested = false
    @State private var resetInProgress = false
    
    var body: some View {
        VStack {
            Spacer()
            
            Button {
                lock()
            } label: {
                HStack {
                    Image(systemName: "lock")
                        .frame(maxWidth: 32, maxHeight: 32)
                    Text("Lock")
                        .font(.title2)
                }
                .frame(maxWidth: 322)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding()
            
            Button {
                resetRequested = true
            } label: {
                if resetInProgress {
                    ProgressView()
                } else {
                    HStack {
                        Image("arrow.circlepath")
                        Text("Reset User Data")
                            .font(.title2)
                    }.frame(maxWidth: 322)
                }
            }
            .buttonStyle(RoundedButtonStyle())
            .padding()
            
            Spacer()
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
    
    private func lock() {
        apiProvider.decodableRequest(with: session, endpoint: .lock) { (result: Result<API.LockApiResponse, MoyaError>) in
            switch result {
            case .success(let payload):
                onOwnerStateUpdated(payload.ownerState)
            case .failure(let err):
                error = err
                showingError = true
            }
        }
    }
}

#if DEBUG
#Preview {
    SettingsTab(session: .sample, onOwnerStateUpdated: {_ in })
}
#endif
