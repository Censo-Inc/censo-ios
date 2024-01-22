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
    var onCancel: () -> Void
    @ViewBuilder var content: () -> Content
    
    private let productIds = [Configuration.appStoreProductId]
    
    @State private var offer: Paywall.Offer?
    
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
                } else if let offer {
                    Paywall(offer: offer, 
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
                if let product = try await Product.products(for: productIds).first {
                    let isEligibleForIntroOffer = await product.subscription?.isEligibleForIntroOffer ?? false
                    offer = Paywall.Offer(product: product, isEligibleForIntroOffer: isEligibleForIntroOffer)
                    actionInProgress = nil
                } else {
                    throw CensoError.productNotFound
                }
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

struct Paywall: View {
    var offer: Offer
    var purchase: (Product) -> Void
    var restorePurchases: () -> Void
    var codeRedeemed: () -> Void
    @State private var displayRedemptionSheet = false
    @State private var displayError = false
    @State private var error = ""
    
    struct Offer {
        var product: Product
        var isEligibleForIntroOffer: Bool
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Group {
                if let subscription = offer.product.subscription {
                    Text("Secure all your seed phrases for\n\(offer.product.displayPrice) / \(subscription.subscriptionPeriod.formatted()).")
                } else {
                    Text("Secure all your seed phrases for \(offer.product.displayPrice).")
                }
            }
            .font(.title)
            .fontWeight(.medium)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal)
            .padding(.bottom)
            
            let trialPeriod = offer.isEligibleForIntroOffer ? offer.product.subscription?.trialPeriod() : nil
            
            if trialPeriod != nil {
                Text("Try for free, cancel anytime")
                    .font(.title)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            
            Spacer()
            
            Image("CensoLogoDarkBlueStacked")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 124)
            
            Spacer()
            
            Button {
                purchase(offer.product)
            } label: {
                VStack {
                    Text("Continue")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let subscription = offer.product.subscription, let trialPeriod {
                        Text("\(trialPeriod.formatted()) free, then \(offer.product.displayPrice) / \(subscription.subscriptionPeriod.formatted())")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(.bottom)
            .accessibilityIdentifier("purchaseButton")

            Button {
                displayRedemptionSheet = true
            } label: {
                Text("Redeem Code")
                    .fontWeight(.semibold)
            }
            .padding()

            HStack {
                Link(destination: Configuration.termsOfServiceURL, label: {
                    Text("Terms")
                        .font(.headline)
                        .fontWeight(.semibold)
                })
                
                Text("|")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Link(destination: Configuration.privacyPolicyURL, label: {
                    Text("Privacy")
                        .fontWeight(.semibold)
                })
                
                Text("|")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Button {
                    restorePurchases()
                } label: {
                    Text("Restore Purchases")
                        .fontWeight(.semibold)

                }
            }
        }
        .padding()
        .offerCodeRedemption(isPresented: $displayRedemptionSheet) { result in
            switch (result) {
            case .success:
                codeRedeemed()
            case .failure(let err):
                SentrySDK.captureWithTag(error: err, tagValue: "Redeem Code")
                displayError = true
                error = err.localizedDescription
            }
        }
        .alert("Error", isPresented: $displayError) {
            Button {
                displayError = false
                error = ""
            } label: { Text("OK") }
        } message: {
            Text(error)
        }
    }
}

private extension Product.SubscriptionInfo {
    func trialPeriod() -> Product.SubscriptionPeriod? {
        guard let introductoryOffer,
              introductoryOffer.paymentMode == Product.SubscriptionOffer.PaymentMode.freeTrial
        else {
            return nil
        }
        
        return introductoryOffer.period
    }
}

private extension Product.SubscriptionPeriod {
    func formatted() -> String {
        switch (self.unit) {
        case .day:
            if value == 1 {
                return "day"
            } else {
                return "\(self.value) days"
            }
        case .week:
            if value == 1 {
                return "7 days"
            } else {
                return "\(self.value) weeks"
            }
        case .month:
            if value == 1 {
                return "month"
            } else {
                return "\(self.value) months"
            }
        case .year:
            if value == 1 {
                return "year"
            } else {
                return "\(self.value) years"
            }
        @unknown default:
            fatalError()
        }
    }
}

#if DEBUG
import Moya

#Preview {
    @State var ownerState = API.OwnerState.initial(.init(authType: .facetec, entropy: .sample, subscriptionStatus: .none, subscriptionRequired: false))
    
    return PaywallGatedScreen(
        session: .sample,
        ownerState: $ownerState,
        onCancel: {}
    ) {
        Text("Behind the paywall")
    }.foregroundColor(.Censo.primaryForeground)
}
#endif
