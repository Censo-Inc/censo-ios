//
//  LabelOwner.swift
//  Approver
//
//  Created by Anton Onyshchenko on 19.12.23.
//

import Foundation
import SwiftUI
import Moya

struct LabelOwner: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var participantId: ParticipantId
    var onComplete: (API.ApproverUser) -> Void
    
    @StateObject private var label = OwnerLabel()
    @State private var submitting = false
    @State private var showingError = false
    @State private var error: Error?
    
    init(session: Session, participantId: ParticipantId, label: String?, onComplete: @escaping (API.ApproverUser) -> Void) {
        self.session = session
        self.participantId = participantId
        self.onComplete = onComplete
        self._label = StateObject(wrappedValue: OwnerLabel(label ?? ""))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            
            Text("Give this person a unique nickname so you can identify them.")
                .font(.body)
                .padding(.bottom)

            VStack(spacing: 0) {
                TextField(text: $label.value) {
                    Text("Enter a nickname...")
                }
                .textFieldStyle(RoundedTextFieldStyle())
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                
                Text(label.isTooLong ? "Can't be longer than \(label.limit) characters" : " ")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.red)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            
            Button {
                submit()
            } label: {
                Group {
                    if submitting {
                        ProgressView()
                    } else {
                        Text("Save")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(.bottom)
            .disabled(submitting || !label.isValid)
        }
        .navigationTitle("Name the person")
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button {
                showingError = false
                error = nil
            } label: {
                Text("OK")
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .padding([.leading, .trailing], 32)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func showError(_ error: Error) {
        self.submitting = false
        self.error = error
        self.showingError = true
    }
    
    private func submit() {
        self.submitting = true
            
        apiProvider.decodableRequest(
            with: session,
            endpoint: .labelOwner(participantId, label.value)
        ) { (result: Result<API.ApproverUser, MoyaError>) in
            switch result {
            case .success(let response):
                onComplete(response)
            case .failure(let error):
                showError(error)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        LabelOwner(
            session: .sample,
            participantId: ParticipantId.sample,
            label: nil,
            onComplete: { _ in }
        )
        .foregroundColor(Color.Censo.primaryForeground)
    }
}
#endif
