//
//  PolicySetup.swift
//  Vault
//
//  Created by Brendan Flood on 9/5/23.
//

import SwiftUI
import Moya
import BigInt

struct GuardianProspect {
    var label: String
    var participantId: BigInt
}

struct PolicyEntry: View {
    @Environment(\.apiProvider) var apiProvider

    
    @State var guardianProspects: [GuardianProspect] = []
    @State var threshold: Int = 0
    @State var nextGuardianName: String = ""
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?
    
    var deviceKey: DeviceKey
    
    var onSuccess: () -> Void
    
    var body: some View {
        NavigationStack{
            VStack {
                
                List{
                    
                    Section(header: Text("Threshold").bold().foregroundColor(Color.black)) {
                        Stepper("\(threshold)", value: $threshold, in: 0...guardianProspects.count)
                    }
                    
                    
                    Section(header: Text("Guardians").bold().foregroundColor(Color.black)) {
                        ForEach(self.guardianProspects, id:\.participantId){ guardian in
                            Text(guardian.label)
                        }.onDelete(perform: delete)
                        
                        HStack(spacing: 3) {
                            TextField("Enter Guardian Name", text: $nextGuardianName)
                                .font(.title3)
                            Button("Add") {
                                if guardianProspects.isEmpty {
                                    threshold = 1
                                }
                                guardianProspects.append(
                                    GuardianProspect(
                                        label: nextGuardianName,
                                        participantId: generateParticipantId()
                                    )
                                )
                                nextGuardianName=""
                                
                            }
                            .disabled(nextGuardianName == "")
                            .buttonStyle(FilledButtonStyle())
                        }
                    }
                
                }
                
                Spacer()

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
                
            }
            .navigationBarTitle("Policy Setup", displayMode: .inline)
            .padding()
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button { } label: { Text("OK") }
            } message: { error in
                Text("There was an error submitting your info.\n\(error.localizedDescription)")
            }
        }
    }
    
    func delete(indexSet: IndexSet) {
        guardianProspects.remove(atOffsets: indexSet)
        if (guardianProspects.count < threshold) {
            threshold = guardianProspects.count
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
                guardians: guardianProspects,
                deviceKey: deviceKey
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
                    guardiansToInvite: policySetupHelper.guardianInvites,
                    encryptedMasterPrivateKey: policySetupHelper.encryptedMasterPrivateKey,
                    masterEncryptionPublicKey: policySetupHelper.masterEncryptionPublicKey
                )
            )
        ) { result in
            switch result {
            case .success(let response) where response.statusCode <= 400:
                onSuccess()
            case .success(let response):
                showError(MoyaError.statusCode(response))
            case .failure(let error):
                showError(error)
            }
        }
    }
}

struct PolicyEntry_Previews: PreviewProvider {
    static var previews: some View {
        PolicyEntry(deviceKey: DeviceKey.sample, onSuccess: {})
    }
}
