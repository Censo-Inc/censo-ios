//
//  PolicySetup.swift
//  Vault
//
//  Created by Brendan Flood on 9/5/23.
//

import SwiftUI
import Moya
import BigInt

struct  PolicyAndGuardianSetup: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss

    enum LoadingState {
        case loading
        case loaded
    }
    
    @State private var guardianProspects: [API.ProspectGuardian] = []
    @State private var threshold: Int = 0
    @State private var nextGuardianName: String = ""
    @State private var loadingState: LoadingState = .loading
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?
    @State private var showingAdd = false
    @State private var allGuardiansConfirmed = false
    
    var onSuccess: () -> Void
    
    var body: some View {
        NavigationView {
            switch (loadingState) {
            case .loading:
                ProgressView().onAppear { reloadUser() }
            case .loaded:
                VStack {
                    
                    Section(header: Text("Guardians").bold().foregroundColor(Color.black)) {
                        List {
                            ForEach(guardianProspects, id:\.participantId){ guardian in
                                switch (guardian.status) {
                                case .confirmed:
                                    HStack(alignment: .center, spacing: 5) {
                                        Text(guardian.label)
                                        Spacer()
                                        Text("Confirmed").foregroundColor(Color.green)
                                    }
                                case .declined:
                                    HStack(alignment: .center, spacing: 5) {
                                        Text(guardian.label)
                                        Spacer()
                                        Text("Declined").foregroundColor(Color.red)
                                    }
                                default:
                                    NavigationLink(guardian.label) {
                                        GuardianOnboarding(guardian: guardian, onSuccess: reloadUser)
                                    }
                                }
                            }.onDelete(perform: deleteGuardian)
                            
                            if showingAdd {
                                HStack(spacing: 3) {
                                    TextField("Enter Guardian Name", text: $nextGuardianName)
                                        .font(.title3)
                                    Button("Add") {
                                        if guardianProspects.isEmpty {
                                            threshold = 1
                                        }
                                        createGuardian(name: nextGuardianName)
                                        
                                        nextGuardianName=""
                                        
                                    }
                                    .disabled(nextGuardianName == "")
                                    .buttonStyle(FilledButtonStyle())
                                }
                                Button {
                                    showingAdd = false
                                } label: {
                                    Image(systemName: "minus")
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                Button {
                                    showingAdd = true
                                } label: {
                                    Image(systemName: "plus")
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    
                    
                    if allGuardiansConfirmed {
                        Spacer()
                        
                        Section(header: Text("Threshold").bold().foregroundColor(Color.black)) {
                            Stepper("\(threshold)", value: $threshold, in: 0...guardianProspects.count)
                        }
                        
                        
                        Button {
                            self.createPolicy()
                        } label: {
                            if inProgress {
                                ProgressView()
                            } else {
                                Text("Create Policy")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .disabled(guardianProspects.isEmpty || threshold == 0 || inProgress)
                        .buttonStyle(FilledButtonStyle())
                    } else  {
                        Spacer()
                    }
                }
            }
        }
        .navigationBarTitle(allGuardiansConfirmed ? "Policy Setup" : "Guardian Setup", displayMode: .inline)
        .navigationBarItems(trailing:
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
        )
        .padding()
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button { } label: { Text("OK") }
        } message: { error in
            Text("There was an error submitting your info.\n\(error.localizedDescription)")
        }
    }
    
    func deleteGuardian(indexSet: IndexSet) {
        if let participantToDelete = indexSet.map({ self.guardianProspects[$0].participantId }).first {
            apiProvider.request(.deleteGuardian(participantToDelete)) { result in
                switch result {
                case .success(let response) where response.statusCode < 400:
                    DispatchQueue.main.async {
                        guardianProspects.remove(atOffsets: indexSet)
                        if (guardianProspects.count < threshold) {
                            threshold = guardianProspects.count
                        }
                    }
                    reloadUser()
                default:
                    break
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        inProgress = false

        self.error = error
        self.showingError = true
    }
        
    private func createPolicy() {
        inProgress = true
        
        var policySetupHelper: PolicySetupHelper
        do {
            policySetupHelper = try PolicySetupHelper(
                threshold: threshold,
                guardians: guardianProspects.map({($0.participantId, try getGuardianPublicKey(status: $0.status))})
            )
        } catch {
            showError(error)
            return
        }

        apiProvider.request(
            .createPolicy(
                API.CreatePolicyApiRequest(
                    intermediatePublicKey: policySetupHelper.intermediatePublicKey,
                    threshold: threshold,
                    guardians: policySetupHelper.guardians,
                    encryptedMasterPrivateKey: policySetupHelper.encryptedMasterPrivateKey,
                    masterEncryptionPublicKey: policySetupHelper.masterEncryptionPublicKey
                )
            )
        ) { result in
            switch result {
            case .success(let response) where response.statusCode < 400:
                inProgress = false
                onSuccess()
            case .success(let response):
                showError(MoyaError.statusCode(response))
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func createGuardian(name: String) {
        apiProvider.decodableRequest(.createGuardian(name: name)) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onOwnerStateUpdate(ownerState: response.ownerState)
                case .failure(let error):
                    showError(error)
                }
            }
    }
    
    private func onOwnerStateUpdate(ownerState: API.OwnerState?) {
        if let ownerState = ownerState {
            switch(ownerState) {
            case .guardianSetup(let guardianSetup):
                guardianProspects = guardianSetup.guardians
                allGuardiansConfirmed = guardianSetup.guardians.count > 0 && guardianSetup.guardians.allSatisfy({isConfirmed(status: $0.status)})
            default:
                break;
            }
        }
    }
    
    private func isConfirmed(status: API.GuardianStatus) ->  Bool {
        switch(status) {
        case .confirmed:
            return true
        default:
            return false
        }
    }
    
    private func getGuardianPublicKey(status: API.GuardianStatus) throws -> Base58EncodedPublicKey {
        switch(status) {
        case .confirmed(let confirmed):
            return confirmed.guardianPublicKey
        default:
            throw PolicySetupError.badPublicKey
        }
    }
    
    private func reloadUser() {
        apiProvider.decodableRequest(.user) { (result: Result<API.User, MoyaError>) in
            switch result {
            case .success(let user):
                onOwnerStateUpdate(ownerState: user.ownerState)
                loadingState = .loaded
            default:
                break
            }
        }
    }
}

struct PolicyAndGuardianSetup_Previews: PreviewProvider {
    static var previews: some View {
        PolicyAndGuardianSetup(onSuccess: {})
    }
}
