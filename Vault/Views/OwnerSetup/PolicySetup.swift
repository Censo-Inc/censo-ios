//
//  PolicySetup.swift
//  Vault
//
//  Created by Brendan Flood on 9/5/23.
//

import SwiftUI
import Moya
import BigInt

struct  PolicySetup: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss

    enum SetupState {
        case loading
        case policySetup
        case enrollment
    }
    
    @State private var guardians: [API.GuardianSetup] = []
    @State private var threshold: Int = 0
    @State private var guardianLabel: String = ""
    @State private var setupState: SetupState = .loading
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?
    @State private var showingAddOrUpdate = false
    @State private var updatingIndex: Int?

    var session: Session
    var onSuccess: () -> Void
    
    var body: some View {
        NavigationView {
            switch (setupState) {
            case .loading:
                ProgressView().onAppear { reloadUser() }
            case .enrollment:
                FacetecAuth(
                    session: session,
                    onSuccess: { response in onSuccess() },
                    onReadyToUploadResults: { biomentryVerificationId, biometryData in
                        self.setupPolicyRequest(biometryVerificationId: biomentryVerificationId, biometryData: biometryData)!
                    }
                )
            case .policySetup:
                VStack {
                    Section(header: Text("Guardians").bold().foregroundColor(Color.black)) {
                        List {
                            ForEach(guardians, id:\.participantId){ guardian in
                                Text(guardian.label)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            deleteGuardian(guardian: guardian)
                                        } label: {
                                            Text("Delete")
                                        }.tint(Color.red)
                                      }
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            showingAddOrUpdate = true
                                            updatingIndex = guardians.firstIndex(where: {$0.participantId == guardian.participantId})!
                                            guardianLabel = guardian.label
                                        } label: {
                                            Text("Update")
                                        }.tint(Color.gray)
                                      }
                            }
                            
                            Button {
                                showingAddOrUpdate = true
                            } label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "plus")
                                    Text("Add another")
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }

                    Spacer()

                    Section(header: Text("Threshold").bold().foregroundColor(Color.black)) {
                        Stepper("\(threshold)", value: $threshold, in: 0...guardians.count)
                    }

                    Button {
                        setupState = .enrollment
                    } label: {
                        if inProgress {
                            ProgressView()
                        } else {
                            Text("Continue Activition")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(guardians.isEmpty || threshold == 0 || inProgress)
                    .buttonStyle(FilledButtonStyle())
                }
            }
        }
        .navigationBarTitle("Policy Setup", displayMode: .inline)
        .navigationBarItems(trailing:
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
        )
        .padding()
        .alert("\(updatingIndex == nil ? "Add" : "Update") Approver", isPresented: $showingAddOrUpdate) {
            TextField("Enter Label", text: $guardianLabel)
                .font(.title3)
            HStack {
                Button("Cancel") {
                    resetAddOrUpdate()
                }
                Button(updatingIndex == nil ? "Add" : "Update") {
                    if let updatingIndex = updatingIndex {
                        guardians[updatingIndex].label = guardianLabel
                    } else {
                        guardians.append(
                            API.GuardianSetup(
                                participantId: ParticipantId(bigInt: generateParticipantId()),
                                label: guardianLabel
                            )
                        )
                    }
                    resetAddOrUpdate()
                }
            }
        } message: {
            Text("Give the approver a label")
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button { } label: { Text("OK") }
        } message: { error in
            Text("There was an error submitting your info.\n\(error.localizedDescription)")
        }
    }
    
    func deleteGuardian(guardian: API.GuardianSetup) {
        if let index = guardians.firstIndex(where: {$0.participantId == guardian.participantId}) {
            guardians.remove(at: index)
        }
    }
    
    private func resetAddOrUpdate() {
        guardianLabel = ""
        showingAddOrUpdate = false
        updatingIndex = nil
    }
    
    private func showError(_ error: Error) {
        inProgress = false

        self.error = error
        self.showingError = true
    }
    
    private func setupPolicyRequest(biometryVerificationId: String, biometryData: API.FacetecBiometry) -> API.Endpoint? {
        return .setupPolicy(
                API.SetupPolicyApiRequest(
                    threshold: threshold,
                    guardians: guardians,
                    biometryVerificationId: biometryVerificationId,
                    biometryData: biometryData
                )
            )
    }
    
    private func onOwnerStateUpdate(ownerState: API.OwnerState?) {
        if let ownerState = ownerState {
            switch(ownerState) {
            case .guardianSetup(let guardianSetup):
                guardians = guardianSetup.guardians.map({ (API.GuardianSetup(participantId: $0.participantId, label: $0.label ))})
                threshold = guardianSetup.threshold ?? 0
            default:
                break;
            }
        }
    }
    
    private func reloadUser() {
        apiProvider.decodableRequest(with: session, endpoint: .user) { (result: Result<API.User, MoyaError>) in
            switch result {
            case .success(let user):
                onOwnerStateUpdate(ownerState: user.ownerState)
                setupState = .policySetup
            default:
                break
            }
        }
    }
}

#if DEBUG
struct PolicySetup_Previews: PreviewProvider {
    static var previews: some View {
        PolicySetup(session: .sample, onSuccess: {})
    }
}

extension Session {
    static var sample: Self {
        .init(deviceKey: .sample, userCredentials: .sample)
    }
}

extension UserCredentials {
    static var sample: Self {
        .init(idToken: Data(), userIdentifier: "userIdentifier")
    }
}
#endif
