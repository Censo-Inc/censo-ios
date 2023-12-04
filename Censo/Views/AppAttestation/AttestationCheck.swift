//
//  AttestationCheck.swift
//  Censo
//
//  Created by Ata Namvari on 2023-11-30.
//

import SwiftUI
import Moya

struct AttestationCheck<Content>: View where Content : View {
    @Environment(\.apiProvider) var apiProvider

    @RemoteResult<API.AttestationKey, API> private var attestationKey

    var session: Session
    var keyId: String
    var onNeedsReset: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        switch attestationKey {
        case .idle:
            ProgressView()
                .onAppear(perform: reload)
        case .loading:
            ProgressView()
        case .success(let key) where key.keyId == keyId:
            content()
        case .success:
            ProgressView()
                .onAppear(perform: onNeedsReset)
        case .failure(MoyaError.underlying(CensoError.resourceNotFound, _)):
            ProgressView()
                .onAppear(perform: onNeedsReset)
        case .failure(let error):
            RetryView(error: error, action: reload)
        }
    }

    private func reload() {
        _attestationKey.reload(with: apiProvider, target: session.target(for: .attestationKey))
    }
}
