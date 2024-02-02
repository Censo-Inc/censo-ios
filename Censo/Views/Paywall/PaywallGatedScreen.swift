//
//  PaywallGatedScreen.swift
//  Censo
//
//  Created by Anton Onyshchenko on 14.11.23.
//

import Foundation
import SwiftUI
import StoreKit
import Sentry
import CryptoKit

struct PaywallGatedScreen<Content: View>: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var ownerState: API.OwnerState
    var ignoreSubscriptionRequired = false
    var onCancel: () -> Void
    @ViewBuilder var content: () -> Content
    
    private let productIds = [
        Configuration.appStoreMonthlyProductId,
        Configuration.appStoreYearlyProductId
    ]
    
    @State private var monthlyOffer: Product?
    @State private var yearlyOffer: Product?

    enum ActionInProgress {
        case loadingProduct
        case purchase(Product)
        case restorePurchases
        case backFromRedemption
    }
    
    @State private var actionInProgress: ActionInProgress?
    @State private var error: Error?
    
    @State private var appStoreTransactionUpdatesTask: _Concurrency.Task<Void, Never>? = nil
    
    var body: some View {
        if Configuration.paywallDisabled {
            content()
        } else {
            Group {
                if ownerState.subscriptionStatus == .active || (ownerState.subscriptionStatus == .none && !ownerState.subscriptionRequired && !ignoreSubscriptionRequired) {
                    content()
                } else {
                    if let actionInProgress {
                        if let error {
                            RetryView(error: error, action: {
                                self.error = nil
                                switch (actionInProgress) {
                                case .loadingProduct: loadProduct()
                                case .purchase(let product): purchase(product)
                                case .restorePurchases: restorePurchases()
                                case .backFromRedemption: self.actionInProgress = nil
                                }
                            })
                        } else {
                            switch (actionInProgress) {
                            case .loadingProduct:
                                ProgressView()
                            case .purchase:
                                ProgressView("Processing your subscription")
                            case .restorePurchases:
                                ProgressView("Restoring your subscription")
                            case .backFromRedemption:
                                // when the `.offerCodeRedemption` sheet closes, we don't know if the user actually
                                // redeemed an offer code or just dismissed the sheet. If they redeemed a code,
                                // `observeAppStoreTransactionUpdates()` will eventually see it, but it can take
                                // a while. Show a progress view for a while to give us a change to see the transaction
                                // and move on without confusing the user by showing the paywall again.
                                ProgressView("Synchronizing subscriptions")
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                            switch self.actionInProgress {
                                            case .backFromRedemption:
                                                self.actionInProgress = nil
                                            default:
                                                break
                                            }
                                        }
                                    }
                                // for some reason, when the `.offerCodeRedemption` sheet closes, the keyboard pops open shortly afterwards
                                // this hack keeps it closed:
                                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                                        UIApplication.shared.closeKeyboard()
                                    }
                            }
                        }
                    } else if let monthlyOffer, let yearlyOffer {
                        Paywall(
                            monthlyOffer: monthlyOffer,
                            yearlyOffer: yearlyOffer,
                            ownerState: ownerState,
                            purchase: purchase,
                            restorePurchases: restorePurchases,
                            redemptionFlowEnded: {
                                if (actionInProgress == nil) {
                                    actionInProgress = .backFromRedemption
                                }
                            }
                        )
                        .onboardingCancelNavBar(onboarding: ownerState.onboarding, onCancel: onCancel)
                    } else {
                        ProgressView()
                            .onAppear() { loadProduct() }
                    }
                }
            }
            .onAppear {
                self.appStoreTransactionUpdatesTask = observeAppStoreTransactionUpdates()
            }
            .onDisappear {
                self.appStoreTransactionUpdatesTask?.cancel()
            }
        }
    }
    
    private func loadProduct() {
        actionInProgress = .loadingProduct
        _Concurrency.Task {
            do {
                let products = try await Product.products(for: productIds)
                guard let monthlyProduct = products.first(where: { product in product.subscription?.subscriptionPeriod.unit == .month &&
                       product.subscription?.subscriptionPeriod.value == 1}),
                      let yearlyProduct = products.first(where: { product in
                          product.subscription?.subscriptionPeriod.unit == .year &&
                          product.subscription?.subscriptionPeriod.value == 1
                      }) else {
                    throw CensoError.productNotFound
                }
                monthlyOffer = monthlyProduct
                yearlyOffer = yearlyProduct
                actionInProgress = .none
            } catch {
                showError(error)
            }
        }
    }
    
    private func purchase(_ product: Product) {
        actionInProgress = .purchase(product)
        _Concurrency.Task {
#if INTEGRATION
            do {
                let fakeTransactionId = "app_\(ownerRepository.userIdentifierHash)_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
                try await submitPurchaseToBackend(
                    fakeTransactionId,
                    AppStore.Environment.sandbox
                )
                actionInProgress = nil
            } catch {
                showError(error)
            }
#else
            do {
                let result = try await product.purchase()
                
                switch result {
                case let .success(.verified(transaction)):
                    try await submitPurchaseToBackend(String(transaction.originalID), transaction.environment)
                    await transaction.finish()
                    actionInProgress = nil
                case .success(.unverified):
                    throw CensoError.purchaseFailed
                case .pending:
                    break
                case .userCancelled:
                    actionInProgress = nil
                @unknown default:
                    actionInProgress = nil
                }
            } catch {
                showError(error)
            }
#endif
        }
    }
    
    private func showError(_ error: Error) {
        self.error = error
    }
    
    private func observeAppStoreTransactionUpdates() -> _Concurrency.Task<Void, Never> {
        _Concurrency.Task(priority: .background) {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else {
                    continue
                }

#if INTEGRATION
                await transaction.finish()
#else
                do {
                    try await submitPurchaseToBackend(String(transaction.originalID), transaction.environment)
                    await transaction.finish()
                } catch {
                    showError(error)
                }
#endif
            }
        }
    }
    
    private func submitPurchaseToBackend(_ originalId: String, _ environment: AppStore.Environment) async throws {
        ownerStateStoreController.replace(
            try await withCheckedThrowingContinuation { continuation in
                ownerRepository.submitPurchase(
                    API.SubmitPurchaseApiRequest(
                        purchase: API.SubmitPurchaseApiRequest.Purchase(
                            originalTransactionId: originalId,
                            environment: environment.rawValue
                        )
                    )
                ) { result in
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response.ownerState)
                    case .failure(let error):
                        SentrySDK.captureWithTag(error: error, tagValue: "Submit Purchase")
                        continuation.resume(throwing: error)
                    }
                }
            }
        )
    }
    
    private func restorePurchases() {
        actionInProgress = .restorePurchases
        _Concurrency.Task {
            do {
                try await AppStore.sync()
                actionInProgress = nil
            } catch {
                showError(error)
            }
        }
    }
}

private extension UIApplication {
    func closeKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#if DEBUG
import Moya

#Preview {
    LoggedInOwnerPreviewContainer {
        PaywallGatedScreen(
            ownerState: API.OwnerState.ready(
                API.OwnerState.Ready(
                    policy: .sample,
                    vault: .sample,
                    authType: .facetec,
                    subscriptionStatus: .none,
                    timelockSetting: .sample,
                    subscriptionRequired: true,
                    onboarded: true,
                    canRequestAuthenticationReset: false
                )
            ),
            onCancel: {}
        ) {
            Text("Behind the paywall")
        }
    }
}
#endif
