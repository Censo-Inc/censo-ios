//
//  RetryView.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-15.
//

import Foundation
import SwiftUI

struct RetryView: View {
    var error: Error
    var action: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text(error.message)
                .multilineTextAlignment(.center)
                .padding()

            Button(action: action) {
                Text("Retry")
                    .frame(width: 100)
            }
            .buttonStyle(FilledButtonStyle())

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func showHelp() {
        if let helpUrl = URL(string: "https://help.censo.co"), UIApplication.shared.canOpenURL(helpUrl) {
            UIApplication.shared.open(helpUrl)
        }
    }
}

import Moya
import Alamofire

extension Error {
    var message: String {
        switch self as Error {
        case MoyaError.statusCode(let response) where response.statusCode == 418:
            return "Censo is currently under maintenance, please try again in a few minutes."
        case MoyaError.underlying(AFError.sessionTaskFailed(let error as NSError), _) where error.code == -1001:
            return "Your request timed out. Please retry"
        case MoyaError.underlying(AFError.sessionTaskFailed(let error as NSError), _) where error.code == -1009:
            return "You don't seem to be connected to the internet. Please check your connection and retry"
        case Keychain.KeychainError.couldNotLoad:
            return "Unable to retrieve data from your keychain"
        default:
            return "Something went wrong"
        }
    }
}

#if DEBUG
struct RetryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RetryView(error: URLError(.badURL), action: { })
                .navigationTitle(Text("Approvals"))
        }
    }
}
#endif
