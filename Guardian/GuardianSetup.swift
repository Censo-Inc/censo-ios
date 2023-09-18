//
//  GuardianSetup.swift
//  Guardian
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI

struct GuardianSetup: View {
    @Environment(\.apiProvider) private var apiProvider

    @RemoteResult<Data, API> private var guardianState

    var deviceKey: DeviceKey

    var body: some View {
        switch guardianState {
        case .idle:
            ProgressView()
                .onAppear(perform: reload)
        case .loading:
            ProgressView()
        case .failure(let error):
            VStack {
                Text(error.localizedDescription)

                Button(action: reload) {
                    Text("Retry")
                }
            }
        case .success:
            EmptyView()
        }
    }

    private func reload() {
        _guardianState.reload(with: apiProvider, target: .guardianState(deviceKey: deviceKey))
    }
}

#if DEBUG
struct GuardianSetup_Previews: PreviewProvider {
    static var previews: some View {
        GuardianSetup(deviceKey: .sample)
    }
}
#endif

