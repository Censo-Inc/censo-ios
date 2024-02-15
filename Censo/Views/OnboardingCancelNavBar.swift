//
//  OnboardingCancelCheck.swift
//  Censo
//
//  Created by Brendan Flood on 1/11/24.
//

import SwiftUI

struct OnboardingCancelNavBar: ViewModifier {
    var onCancel: () -> Void
    var navigationTitle: String?
    var onboarding: Bool = true
    var showAsBack = false
    
    func body(content: Content) -> some View {
        if onboarding {
            NavigationStack {
                content
                    .navigationInlineTitle(navigationTitle ?? "")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            DismissButton(icon: showAsBack ? .back : .close, action: onCancel)
                        }
                    }
            }
        } else if let navigationTitle = navigationTitle  {
            NavigationStack {
                content
                    .navigationInlineTitle(navigationTitle)
            }
        } else {
            content
        }
    }
}

extension View {
    func onboardingCancelNavBar(onCancel: @escaping () -> Void, showAsBack: Bool = false) -> some View {
        modifier(OnboardingCancelNavBar(onCancel: onCancel, showAsBack: showAsBack))
    }
    
    func onboardingCancelNavBar(navigationTitle: String, onCancel: @escaping () -> Void, showAsBack: Bool = false) -> some View {
        modifier(OnboardingCancelNavBar(onCancel: onCancel, navigationTitle: navigationTitle, showAsBack: showAsBack))
    }
    
    func onboardingCancelNavBar(onboarding: Bool, onCancel: @escaping () -> Void) -> some View {
        modifier(OnboardingCancelNavBar(onCancel: onCancel, onboarding: onboarding))
    }
    
    func onboardingCancelNavBar(onboarding: Bool, navigationTitle: String, onCancel: @escaping () -> Void) -> some View {
        modifier(OnboardingCancelNavBar(onCancel: onCancel, navigationTitle: navigationTitle, onboarding: onboarding))
    }
}
