//
//  Paywall.swift
//  Censo
//
//  Created by Ben Holzman on 1/25/24.
//

import Foundation
import SwiftUI
import Sentry
import StoreKit

struct Paywall: View {
    var monthlyOffer: Product
    var yearlyOffer: Product
    var ownerState: API.OwnerState
    var purchase: (Product) -> Void
    var restorePurchases: () -> Void
    var redemptionFlowEnded: () -> Void
    @State private var displayRedemptionSheet = false
    @State private var displayError = false
    @State private var error = ""
    @State private var displaySubscriptionDecline = false
    
    func monthFormatter() -> DateComponentsFormatter {
        let monthFormatter = DateComponentsFormatter()
        monthFormatter.allowedUnits = [.month]
        monthFormatter.unitsStyle = .full
        return monthFormatter
    }

    func priceFormatter(locale: Locale) -> NumberFormatter {
        let priceFormatter = NumberFormatter()
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = locale
        return priceFormatter
    }

    func percentChange(yearlyPrice: Decimal, monthlyPrice: Decimal) -> String? {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return formatter.string(for: (100.0 * ((monthlyPrice * 12) - yearlyPrice) / (monthlyPrice * 12)))
    }
    
    func seedPhraseCount() -> String {
        let count = switch ownerState {
        case .ready(let ready):
            ready.vault.seedPhrases.count
        case .initial:
            0
        }
        return if count < 2 {
            "of your seed phrases."
        } else {
            "\(count) of your seed phrases."
        }
    }
    
    var body: some View {
        VStack {
            Spacer().frame(maxHeight: 75)
            ZStack(alignment: .top) {
                Color("AquaBackground")
                Image("CensoLogo")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .offset(x: 0, y: -50)
                VStack {
                    Spacer().frame(maxHeight: 75)
                    HStack {
                        if (ownerState.subscriptionRequired && ownerState.subscriptionStatus != .active) {
                            Text("Your subscription has expired. Renew to keep all \(seedPhraseCount())")
                                .font(.title)
                                .fontWeight(.medium)
                                .padding([.horizontal], 20)
                                .padding(.bottom)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("Secure all your\nSeed Phrases for good.\nAccess anytime.")
                                .font(.title)
                                .fontWeight(.medium)
                                .padding([.horizontal], 20)
                                .padding(.bottom)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }

                    Spacer()
                    
                    Button {
                        purchase(yearlyOffer)
                    } label: {
                        VStack {
                            Text("\(yearlyOffer.displayPrice) / \(yearlyOffer.subscription!.subscriptionPeriod.formatted())")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .accessibilityIdentifier("purchaseYearlyButton")
                    .padding([.horizontal], 20)

                    if let monthlyPrice = priceFormatter(locale: yearlyOffer.priceFormatStyle.locale).string(from: yearlyOffer.price / 12 as NSNumber)
                    {
                        let monthsText = formatUnitAndValue(unit: .month, value: 12)

                        if let pctChange = percentChange(yearlyPrice: yearlyOffer.price, monthlyPrice: monthlyOffer.price) {
                            Text("\(monthsText) **at \(monthlyPrice) / \(formatUnitAndValue(unit: .month, value: 1))** - save \(pctChange)%")
                                .font(.subheadline)
                        } else {
                            Text("\(monthsText) **at \(monthlyPrice) / \(formatUnitAndValue(unit: .month, value: 1))**")
                                .font(.subheadline)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        purchase(monthlyOffer)
                    } label: {
                        VStack {
                            Text("\(monthlyOffer.displayPrice) / \(monthlyOffer.subscription!.subscriptionPeriod.formatted())")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .accessibilityIdentifier("purchaseMonthlyButton")
                    .padding([.horizontal], 20)

                    if (ownerState.subscriptionRequired && ownerState.subscriptionStatus != .active) {
                        Button {
                            displaySubscriptionDecline = true
                        } label: {
                            Text("No, thanks")
                                .fontWeight(.semibold)
                        }
                        .padding()
                    }

                    Button {
                        displayRedemptionSheet = true
                    } label: {
                        Text("Redeem Code")
                            .fontWeight(.semibold)
                    }
                    .padding()
                }
                .padding()

            }

            Spacer().frame(maxHeight: 50)

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
        .offerCodeRedemption(isPresented: $displayRedemptionSheet) { result in
            switch (result) {
            case .success:
                // success does not mean the user redeemed a code, just means the
                // offerCodeRedemption sheet was dismissed
                redemptionFlowEnded()
            case .failure(let err):
                SentrySDK.captureWithTag(error: err, tagValue: "Redeem Code")
                displayError = true
                error = err.localizedDescription
            }
        }
        .sheet(isPresented: $displaySubscriptionDecline) {
            SubscriptionDecline(ownerState: ownerState)
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

private func formatUnitAndValue(unit: Product.SubscriptionPeriod.Unit, value: Int) -> String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full
    var dateComponents: DateComponents?
    var fallbackUnit: String?
    switch unit {
    case .day:
        formatter.allowedUnits = [.day]
        dateComponents = DateComponents(day: value)
        fallbackUnit = "day"
    case .week:
        formatter.allowedUnits = [.weekOfYear]
        dateComponents = DateComponents(weekOfYear: value)
        fallbackUnit = "week"
    case .month:
        formatter.allowedUnits = [.month]
        dateComponents = DateComponents(month: value)
        fallbackUnit = "month"
    case .year:
        formatter.allowedUnits = [.year]
        dateComponents = DateComponents(year: value)
        fallbackUnit = "year"
    @unknown default:
        fatalError()
    }

    // if value is 1, remove the 1 (we want to say "$3.99 / month" not "$3.99 / 1 month")
    let formattedPeriod = formatter.string(from: dateComponents!)
    if value == 1 {
        if let r = try? Regex("\\s*1\\s*") {
            return formattedPeriod?.replacing(r, with: "") ?? fallbackUnit!
        } else {
            return fallbackUnit!
        }
    } else {
        return formattedPeriod ?? fallbackUnit!
    }
}

private extension Product.SubscriptionPeriod {
    func formatted() -> String {
        return formatUnitAndValue(unit: self.unit, value: self.value)
    }
}
