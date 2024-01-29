//
//  PaywallGatedScreen.swift
//  Censo
//
//  Created by Anton Onyshchenko on 14.11.23.
//

import Foundation
import SwiftUI
import StoreKit
import Moya
import Sentry
import CryptoKit

struct PaywallGatedScreen<Content: View>: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    @Binding var ownerState: API.OwnerState
    var ignoreSubscriptionRequired = false
    var reloadOwnerState: () -> Void
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
    }
    
    @State private var actionInProgress: ActionInProgress?
    @State private var error: Error?
    
    @State private var appStoreTransactionUpdatesTask: _Concurrency.Task<Void, Never>? = nil
    
    var body: some View {
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
                        }
                    }
                } else if let monthlyOffer, let yearlyOffer {
                    Paywall(
                        monthlyOffer: monthlyOffer,
                        yearlyOffer: yearlyOffer,
                        ownerState: $ownerState,
                        reloadOwnerState: reloadOwnerState,
                        session: session,
                        purchase: purchase,
                        restorePurchases: restorePurchases,
                        codeRedeemed: {}
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
                let fakeTransactionId = "app_\(session.userCredentials.userIdentifierHash())_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
                try await submitPurchaseToBackend(
                    session,
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
                    try await submitPurchaseToBackend(session, String(transaction.originalID), transaction.environment)
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
                    try await submitPurchaseToBackend(session, String(transaction.originalID), transaction.environment)
                    await transaction.finish()
                } catch {
                    showError(error)
                }
#endif
            }
        }
    }
    
    private func submitPurchaseToBackend(_ session: Session, _ originalId: String, _ environment: AppStore.Environment) async throws {
        ownerState = try await withCheckedThrowingContinuation { continuation in
            apiProvider.decodableRequest(
                with: session,
                endpoint: .submitPurchase(API.SubmitPurchaseApiRequest(
                    purchase: API.SubmitPurchaseApiRequest.Purchase(
                        originalTransactionId: originalId,
                        environment: environment.rawValue
                    )
                ))
            ) { (result: Result<API.SubmitPurchaseApiResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response.ownerState)
                case .failure(let error):
                    SentrySDK.captureWithTag(error: error, tagValue: "Submit Purchase")
                    continuation.resume(throwing: error)
                }
            }
        }
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

#if DEBUG
import Moya

#Preview {
    let ownerState = Binding {
        API.OwnerState.ready(
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
        )
    } set: { _ in }

    return PaywallGatedScreen(
        session: .sample,
        ownerState: ownerState,
        reloadOwnerState: {},
        onCancel: {}
    ) {
        Text("Behind the paywall")
    }.foregroundColor(.Censo.primaryForeground)
}
#endif
