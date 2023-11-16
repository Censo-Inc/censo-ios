//
//  TermsOfUse.swift
//  Censo
//
//  Created by Ben Holzman on 10/25/23.
//

import SwiftUI
import WebKit

struct TermsOfUse: View {
    @State var text: String
    @State var isReview: Bool = false

    var onAccept: () -> Void

    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            if (isReview) {
                WebView(text: $text)
                    .frame(minWidth: 0, maxWidth: .infinity)
                Divider()
            } else {

                Image("Files")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 130)

                Text("Terms of Use")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()

                Text("We built Censo to allow you to secure your seed phrases while maintaining your privacy and control. Our Terms of Use support these principles. Please read and accept to continue.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .padding()

                Button {
                    isReview = true
                } label: {
                    Text("Review Terms of Use")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal)
                .padding(.bottom)
            }

            Button {
                onAccept()
            } label: {
                Text("Accept & Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(.horizontal)
            .padding(.bottom)

            Text("By tapping Accept & Continue, you agree to our Terms of Use.")
                .font(.system(size: 12.0))
        }
    }
}

struct WebView: UIViewRepresentable {
  @Binding var text: String
   
  func makeUIView(context: Context) -> WKWebView {
      return WKWebView()
  }
   
  func updateUIView(_ uiView: WKWebView, context: Context) {
    uiView.loadHTMLString(text, baseURL: nil)
  }
}

extension TermsOfUse {
    static let v0_2: String = """
<h1 id="acceptance-of-terms">ACCEPTANCE OF TERMS</h1>
<h2
id="censo-inc.-censo-provides-access-to-and-use-of-its-websites-and-certain-solutions-for-storage-and-management-of-seed-phrases-used-by-crypto-wallet-owners-and-related-services-collectively-the-service-subject-to-the-terms-and-conditions-in-these-terms-of-use-the-tou.-censo-may-in-its-sole-discretion-update-the-tou-at-any-time.-you-can-access-and-review-the-most-current-version-of-the-tou-at-the-url-for-this-page-or-by-clicking-on-the-terms-of-use-link-within-the-service-or-as-otherwise-made-available-by-censo.">Censo,
Inc. (“<u>Censo</u>”) provides access to and use of its websites and
certain solutions for storage and management of seed phrases used by
crypto wallet owners and related services (collectively, the
“<u>Service</u>”), subject to the terms and conditions in these Terms of
Use (the “<u>TOU</u>”). Censo may, in its sole discretion, update the
TOU at any time. You can access and review the most-current version of
the TOU at the URL for this page or by clicking on the “Terms of Use”
link within the Service or as otherwise made available by Censo.</h2>
<h2
id="please-review-the-tou-carefully.-it-imposes-binding-arbitration-and-a-waiver-of-class-actions.-the-tou-requires-binding-arbitration-to-resolve-any-dispute-or-claim-arising-from-or-relating-to-the-tou-or-your-access-to-or-use-of-the-service-including-the-validity-applicability-or-interpretation-of-the-tou-each-a-claim.-you-agree-that-any-claim-will-be-resolved-only-on-an-individual-basis-and-not-in-a-class-collective-consolidated-or-representative-action-arbitration-or-other-similar-process.-please-review-section-20-carefully-to-understand-your-rights-and-obligations-with-respect-to-the-resolution-of-any-claim.">PLEASE
REVIEW THE TOU CAREFULLY. IT IMPOSES <strong>BINDING
ARBITRATION</strong> AND A <strong>WAIVER OF CLASS ACTIONS</strong>. THE
TOU REQUIRES BINDING ARBITRATION TO RESOLVE ANY DISPUTE OR CLAIM ARISING
FROM OR RELATING TO THE TOU OR YOUR ACCESS TO OR USE OF THE SERVICE,
INCLUDING THE VALIDITY, APPLICABILITY OR INTERPRETATION OF THE TOU
(EACH, A “<u>CLAIM</u>”). YOU AGREE THAT ANY CLAIM WILL BE RESOLVED ONLY
ON AN INDIVIDUAL BASIS AND NOT IN A CLASS, COLLECTIVE, CONSOLIDATED OR
REPRESENTATIVE ACTION, ARBITRATION OR OTHER SIMILAR PROCESS. PLEASE
REVIEW SECTION 20 CAREFULLY TO UNDERSTAND YOUR RIGHTS AND OBLIGATIONS
WITH RESPECT TO THE RESOLUTION OF ANY CLAIM.</h2>
<h2
id="by-accessing-or-using-the-service-you-agree-to-be-bound-by-the-tou-including-any-updates-or-revisions-posted-here-or-otherwise-communicated-to-you.-if-you-are-entering-into-the-tou-on-behalf-of-a-company-or-other-legal-entity-you-represent-and-warrant-that-you-are-authorized-and-lawfully-able-to-bind-such-entity-to-the-tou-in-which-case-the-term-you-will-refer-to-such-entity.-if-you-do-not-have-such-authority-or-if-you-do-not-agree-with-the-terms-and-conditions-of-the-tou-you-may-not-access-or-use-the-service-and-you-must-uninstall-any-components-of-the-service-from-any-device-within-your-custody-or-control.">BY
ACCESSING OR USING THE SERVICE, YOU AGREE TO BE BOUND BY THE TOU,
INCLUDING ANY UPDATES OR REVISIONS POSTED HERE OR OTHERWISE COMMUNICATED
TO YOU. IF YOU ARE ENTERING INTO THE TOU ON BEHALF OF A COMPANY OR OTHER
LEGAL ENTITY, YOU REPRESENT AND WARRANT THAT YOU ARE AUTHORIZED AND
LAWFULLY ABLE TO BIND SUCH ENTITY TO THE TOU, IN WHICH CASE THE TERM
“YOU” WILL REFER TO SUCH ENTITY. IF YOU DO NOT HAVE SUCH AUTHORITY, OR
IF YOU DO NOT AGREE WITH THE TERMS AND CONDITIONS OF THE TOU, YOU MAY
NOT ACCESS OR USE THE SERVICE, AND YOU MUST UNINSTALL ANY COMPONENTS OF
THE SERVICE FROM ANY DEVICE WITHIN YOUR CUSTODY OR CONTROL.</h2>
<h2
id="you-represent-and-warrant-that-you-are-at-least-18-years-of-age-or-the-age-of-majority-in-your-jurisdiction-whichever-is-greater-and-of-legal-age-to-form-a-binding-contract.-you-further-represent-and-warrant-that-you-are-not-a-person-barred-from-accessing-or-using-the-service-under-the-laws-of-your-country-of-residence-or-any-other-applicable-jurisdiction.">You
represent and warrant that you are at least 18 years of age or the age
of majority in your jurisdiction, whichever is greater, and of legal age
to form a binding contract. You further represent and warrant that you
are not a person barred from accessing or using the Service under the
laws of your country of residence or any other applicable
jurisdiction.</h2>
<h1 id="other-agreements-and-terms">Other Agreements and terms</h1>
<h2
id="in-addition-to-the-tou-your-access-to-and-use-of-the-service-are-further-subject-to-the-censo-privacy-policy-and-any-usage-or-other-policies-relating-to-the-service-posted-or-otherwise-made-available-to-you-by-censo-including-any-purchase-subscription-or-other-similar-terms-posted-within-the-service-the-privacy-policy-and-any-such-usage-or-other-policies-collectively-additional-terms.-the-additional-terms-are-part-of-the-tou-and-are-hereby-incorporated-by-reference-and-you-agree-to-be-bound-by-the-additional-terms.">In
addition to the TOU, your access to and use of the Service are further
subject to the Censo Privacy Policy and any usage or other policies
relating to the Service posted or otherwise made available to you by
Censo, including any purchase, subscription or other similar terms
posted within the Service (the Privacy Policy and any such usage or
other policies, collectively, “<u>Additional Terms</u>”). The Additional
Terms are part of the TOU and are hereby incorporated by reference, and
you agree to be bound by the Additional Terms.</h2>
<h2
id="you-acknowledge-and-agree-that-i-by-accessing-or-using-the-service-censo-may-collect-use-disclose-store-and-process-information-about-you-in-accordance-with-the-tou-including-any-additional-terms-and-ii-technical-processing-and-transmission-of-data-including-your-content-defined-in-section-8a-associated-with-the-service-may-require-transmissions-over-various-networks-and-changes-to-conform-and-adapt-to-technical-requirements-of-connecting-networks-or-devices.">You
acknowledge and agree that: (i) by accessing or using the Service, Censo
may collect, use, disclose, store and process information about you in
accordance with the TOU, including any Additional Terms; and (ii)
technical processing and transmission of data, including Your Content
(defined in Section 8(a)), associated with the Service may require
transmissions over various networks and changes to conform and adapt to
technical requirements of connecting networks or devices.</h2>
<h1 id="fees-and-taxes">Fees and Taxes</h1>
<h2
id="you-are-solely-responsible-for-any-data-usage-and-other-charges-assessed-by-mobile-cable-internet-or-other-communications-services-providers-for-your-access-to-and-use-of-the-service.-some-features-of-the-service-are-free-to-use-but-fees-may-apply-for-subscriptions-premium-features-and-other-components-paid-subscriptions.-if-there-is-a-fee-listed-for-any-portion-of-the-service-including-any-mobile-app-as-defined-in-section-4a-by-accessing-or-using-that-portion-you-agree-to-pay-the-fee.-your-access-to-the-service-may-be-suspended-or-terminated-if-you-do-not-make-payment-in-full-when-due.-if-you-sign-up-for-a-paid-subscription-your-paid-subscription-will-automatically-renew-at-the-conclusion-of-the-then-current-term-unless-you-turn-off-auto-renewal-in-accordance-with-the-instructions-provided-by-the-applicable-app-store-through-which-you-purchase-the-paid-subscription.-ceasing-to-access-or-use-the-service-or-uninstalling-a-mobile-app-will-not-automatically-cancel-your-paid-subscription-or-turn-off-auto-renewal.-you-must-cancel-your-paid-subscription-or-turn-off-auto-renewal-to-end-recurring-charges.-if-you-simply-uninstall-the-mobile-apps-without-canceling-your-paid-subscription-or-turning-off-auto-renewal-the-recurring-charges-for-your-paid-subscription-will-continue.-canceling-a-paid-subscription-or-turning-off-auto-renewal-will-not-entitle-you-to-a-refund-of-any-fees-already-paid-and-previously-charged-fees-will-not-be-pro-rated-based-upon-cancellation.">You
are solely responsible for any data, usage and other charges assessed by
mobile, cable, internet or other communications services providers for
your access to and use of the Service. Some features of the Service are
free to use, but fees may apply for subscriptions, premium features and
other components (“<u>Paid Subscriptions</u>”). If there is a fee listed
for any portion of the Service (including any Mobile App, as defined in
Section 4(a)), by accessing or using that portion, you agree to pay the
fee. Your access to the Service may be suspended or terminated if you do
not make payment in full when due. If you sign up for a Paid
Subscription, your Paid Subscription will automatically renew at the
conclusion of the then-current term unless you turn off auto-renewal in
accordance with the instructions provided by the applicable app store
through which you purchase the Paid Subscription. Ceasing to access or
use the Service or uninstalling a Mobile App will not automatically
cancel your Paid Subscription or turn off auto-renewal. You must cancel
your Paid Subscription or turn off auto-renewal to end recurring
charges. If you simply uninstall the Mobile Apps without canceling your
Paid Subscription or turning off auto-renewal, the recurring charges for
your Paid Subscription will continue. Canceling a Paid Subscription or
turning off auto-renewal will not entitle you to a refund of any fees
already paid, and previously charged fees will not be pro-rated based
upon cancellation.</h2>
<h2
id="if-you-purchase-a-paid-subscription-through-a-third-party-such-as-through-an-in-app-purchase-processed-by-an-app-store-separate-terms-and-conditions-with-such-third-party-may-apply-to-your-access-or-use-of-the-service-in-addition-to-the-tou.-please-contact-the-third-party-regarding-any-refunds-or-to-manage-your-paid-subscription.">If
you purchase a Paid Subscription through a third party, such as through
an in-app purchase processed by an app store, separate terms and
conditions with such third party may apply to your access or use of the
Service in addition to the TOU. Please contact the third party regarding
any refunds or to manage your Paid Subscription.</h2>
<h2
id="any-and-all-amounts-payable-hereunder-by-you-are-exclusive-of-any-value-added-sales-use-excise-or-other-similar-taxes-collectively-taxes.-you-are-solely-responsible-for-paying-all-applicable-taxes-except-for-any-taxes-based-upon-censos-net-income.-if-censo-has-the-legal-obligation-to-collect-any-taxes-you-shall-reimburse-censo-upon-invoice.-taxes-if-applicable-are-calculated-based-on-the-information-you-provide-and-the-applicable-rate-at-the-time-of-your-monthly-charge.">Any
and all amounts payable hereunder by you are exclusive of any
value-added, sales, use, excise or other similar taxes (collectively,
“<u>Taxes</u>”). You are solely responsible for paying all applicable
Taxes, except for any Taxes based upon Censo’s net income. If Censo has
the legal obligation to collect any Taxes, you shall reimburse Censo
upon invoice. Taxes, if applicable, are calculated based on the
information you provide and the applicable rate at the time of your
monthly charge.</h2>
<h1 id="access-to-and-use-of-the-service">Access to and Use of the
Service</h1>
<h2
id="subject-to-your-compliance-with-the-tou-including-all-additional-terms-in-all-material-respects-censo-grants-you-a-limited-non-exclusive-non-transferable-non-sublicensable-revocable-right-to-i-access-and-view-pages-within-the-service-ii-access-and-use-any-online-software-application-and-other-similar-component-within-the-service-to-the-extent-that-the-service-provides-you-with-access-to-or-use-of-such-component-but-only-in-the-form-made-accessible-by-censo-within-the-service-and-iii-install-run-and-operate-mobile-applications-that-censo-makes-available-for-accessing-or-using-the-service-each-a-mobile-app-on-a-mobile-device-that-you-own-or-control-but-only-in-executable-machine-readable-object-code-form.">Subject
to your compliance with the TOU, including all Additional Terms, in all
material respects, Censo grants you a limited, non-exclusive,
non-transferable, non-sublicensable, revocable right to: (i) access and
view pages within the Service; (ii) access and use any online software,
application and other similar component within the Service, to the
extent that the Service provides you with access to or use of such
component, but only in the form made accessible by Censo within the
Service; and (iii) install, run and operate mobile applications that
Censo makes available for accessing or using the Service (each a,
“<u>Mobile App</u>”) on a mobile device that you own or control, but
only in executable, machine-readable, object code form.</h2>
<h2
id="censo-makes-available-mobile-apps-for-the-storage-and-management-of-seed-phrases-each-a-seed-phrase-used-to-access-digital-wallets-each-a-wallet-through-which-tokens-cryptocurrencies-and-other-crypto-or-blockchain-based-digital-assets-are-stored-collectively-digital-assets.-to-store-and-manage-seed-phrases-you-access-and-use-a-version-of-the-mobile-apps-for-owners-the-owner-app.-within-the-owner-app-you-may-optionally-assign-third-parties-you-trust-to-help-confirm-that-you-are-entitled-to-access-the-seed-phrases-stored-using-your-owner-app-each-an-approver.">Censo
makes available Mobile Apps for the storage and management of seed
phrases (each, a “<u>Seed Phrase</u>”) used to access digital wallets
(each, a “<u>Wallet</u>”) through which tokens, cryptocurrencies and
other crypto or blockchain-based digital assets are stored
(collectively, “<u>Digital Assets</u>”). To store and manage Seed
Phrases, you access and use a version of the Mobile Apps for owners (the
“<u>Owner App</u>”). Within the Owner App, you may optionally assign
third parties you trust to help confirm that you are entitled to access
the Seed Phrases stored using your Owner App (each, an
“<u>Approver</u>”).</h2>
<h2
id="approvers-use-a-version-of-the-mobile-app-set-up-to-perform-limited-approver-functions-the-approver-app.-use-of-the-approver-app-is-free-and-does-not-require-a-paid-subscription.-although-setting-up-approvers-in-the-owner-app-is-optional-failing-to-do-so-may-limit-your-ability-to-recover-access-to-your-seed-phrases-stored-using-your-owner-app-if-you-lose-access-to-the-app-store-account-associated-with-your-access-to-and-use-of-the-owner-app-the-app-store-account.">Approvers
use a version of the Mobile App set up to perform limited Approver
functions (the “<u>Approver App</u>”). Use of the Approver App is free
and does not require a Paid Subscription. Although setting up Approvers
in the Owner App is optional, failing to do so may limit your ability to
recover access to your Seed Phrases stored using your Owner App if you
lose access to the app store account associated with your access to and
use of the Owner App (the “<u>App Store Account</u>”).</h2>
<h2
id="access-to-and-use-of-the-owner-app-requires-an-active-valid-paid-subscription.-if-you-do-not-maintain-an-active-valid-paid-subscription-you-will-not-be-able-to-access-or-use-your-owner-app-or-the-seed-phrases-stored-using-your-owner-app-in-which-case-you-may-not-be-able-to-access-digital-assets-stored-within-wallets-protected-using-the-applicable-seed-phrases.">Access
to and use of the Owner App requires an active, valid Paid Subscription.
If you do not maintain an active, valid Paid Subscription, you will not
be able to access or use your Owner App or the Seed Phrases stored using
your Owner App, in which case you may not be able to access Digital
Assets stored within Wallets protected using the applicable Seed
Phrases.</h2>
<h2
id="access-to-and-use-of-the-owner-app-requires-that-you-authenticate-your-identity-i-through-3d-liveness-verification-which-may-include-the-use-of-face-scans-performed-using-your-mobile-device-liveness-verification-or-ii-by-setting-up-a-password-password-verification.-if-you-do-not-set-up-or-use-the-liveness-verification-or-password-verification-functionality-properly-you-will-not-be-able-to-access-or-use-your-owner-app-or-the-seed-phrases-stored-using-your-owner-app-in-which-case-you-may-not-be-able-to-access-digital-assets-stored-within-wallets-protected-using-the-applicable-seed-phrases.-with-respect-to-your-use-of-password-verification-a-if-you-lose-your-password-your-password-cannot-be-reset-or-recovered-by-censo-and-b-you-are-solely-responsible-for-keeping-remembering-and-safeguarding-your-password-and-any-losses-including-loss-of-digital-assets-arising-from-your-failure-to-keep-remember-or-safeguard-your-password.">Access
to and use of the Owner App requires that you authenticate your
identity: (i) through 3D liveness verification, which may include the
use of face scans performed using your mobile device (“<u>Liveness
Verification</u>”); or (ii) by setting up a password (“<u>Password
Verification</u>”). If you do not set up or use the Liveness
Verification or Password Verification functionality properly, you will
not be able to access or use your Owner App or the Seed Phrases stored
using your Owner App, in which case you may not be able to access
Digital Assets stored within Wallets protected using the applicable Seed
Phrases. With respect to your use of Password Verification: (A) if you
lose your password, your password cannot be reset or recovered by Censo;
and (B) you are solely responsible for keeping, remembering and
safeguarding your password and any losses, including loss of Digital
Assets, arising from your failure to keep, remember or safeguard your
password.</h2>
<h2
id="if-you-access-or-use-an-owner-app-to-manage-store-or-access-seed-phrases-you-represent-and-warrant-that-you-have-proper-authorization-from-all-parties-with-a-legal-interest-in-the-seed-phrases-and-the-digital-assets-stored-within-wallets-protected-using-the-applicable-seed-phrases-to-manage-store-or-access-such-seed-phrases.">If
you access or use an Owner App to manage, store or access Seed Phrases,
you represent and warrant that you have proper authorization from all
parties with a legal interest in the Seed Phrases and the Digital Assets
stored within Wallets protected using the applicable Seed Phrases to
manage, store or access such Seed Phrases. </h2>
<h1 id="ios-mobile-apps">IOS Mobile Apps</h1>
<h2
id="if-any-mobile-app-is-downloaded-by-you-from-the-apple-inc.-apple-app-store-each-an-ios-mobile-app-the-right-set-forth-in-section-4aiii-with-respect-to-such-ios-mobile-app-is-further-subject-to-your-compliance-in-all-material-respects-with-the-terms-and-conditions-of-the-usage-rules-set-forth-in-the-apple-app-store-terms-of-service.">If
any Mobile App is downloaded by you from the Apple Inc. (“<u>Apple</u>”)
App Store (each, an “<u>iOS Mobile App</u>”), the right set forth in
Section 4(a)(iii) with respect to such iOS Mobile App is further subject
to your compliance in all material respects with the terms and
conditions of the Usage Rules set forth in the Apple App Store Terms of
Service.</h2>
<h2
id="with-respect-to-any-ios-mobile-app-you-and-censo-acknowledge-and-agree-that-the-tou-is-concluded-between-you-and-censo-only-and-not-with-apple-and-apple-is-not-responsible-for-ios-mobile-apps-and-the-contents-thereof.-apple-has-no-obligation-whatsoever-to-furnish-any-maintenance-and-support-services-with-respect-to-ios-mobile-apps.-censo-not-apple-is-responsible-for-addressing-any-claims-from-you-or-any-third-party-relating-to-ios-mobile-apps-or-your-possession-andor-use-of-ios-mobile-apps-including-product-liability-claims-any-claim-that-ios-mobile-apps-fail-to-conform-to-any-applicable-legal-or-regulatory-requirement-and-claims-arising-under-consumer-protection-or-similar-legislation.-apple-and-apples-subsidiaries-are-third-party-beneficiaries-of-the-tou-with-respect-to-ios-mobile-apps-and-apple-shall-have-the-right-and-will-be-deemed-to-have-accepted-the-right-to-enforce-the-tou-against-you-as-a-third-party-beneficiary-hereof-with-respect-to-ios-mobile-apps.-subject-to-section-14-censo-not-apple-shall-be-solely-responsible-for-the-investigation-defense-settlement-and-discharge-of-any-intellectual-property-infringement-claim-attributable-to-ios-mobile-apps.">With
respect to any iOS Mobile App, you and Censo acknowledge and agree that
the TOU is concluded between you and Censo only, and not with Apple, and
Apple is not responsible for iOS Mobile Apps and the contents thereof.
Apple has no obligation whatsoever to furnish any maintenance and
support services with respect to iOS Mobile Apps. Censo, not Apple, is
responsible for addressing any claims from you or any third party
relating to iOS Mobile Apps or your possession and/or use of iOS Mobile
Apps, including product liability claims, any claim that iOS Mobile Apps
fail to conform to any applicable legal or regulatory requirement, and
claims arising under consumer protection or similar legislation. Apple
and Apple’s subsidiaries are third-party beneficiaries of the TOU with
respect to iOS Mobile Apps, and Apple shall have the right (and will be
deemed to have accepted the right) to enforce the TOU against you as a
third-party beneficiary hereof with respect to iOS Mobile Apps. Subject
to Section 14, Censo, not Apple, shall be solely responsible for the
investigation, defense, settlement and discharge of any intellectual
property infringement claim attributable to iOS Mobile Apps.</h2>
<h1 id="third-party-components">Third-Party Components</h1>
<p>Some components of the Service may be provided with or incorporate
third-party components licensed under open source license agreements or
other third-party license terms (collectively, “<u>Third-Party
Components</u>”). Third-Party Components are subject to separate terms
and conditions set forth in the respective license agreements relating
to such components. For more information about Third-Party Components,
please see <span>https://censo.co/legal/3rd-party</span>.</p>
<h1 id="external-materials-and-third-party-services">External Materials
and Third-Party Services</h1>
<p>The Service or users of the Service may provide links or other
connections to other websites or resources. Censo does not endorse and
is not responsible for any content, advertising, products, services or
other materials on or available through such sites or resources
(“<u>External Materials</u>”). External Materials are subject to
different terms of use and privacy policies. You are responsible for
reviewing and complying with such terms of use and privacy policies.</p>
<h1 id="responsibility-for-content">RESPONSIBILITY FOR CONTENT</h1>
<h2
id="all-information-data-data-records-databases-text-software-music-sounds-photographs-images-graphics-videos-messages-scripts-tags-and-other-materials-accessible-through-the-service-whether-publicly-posted-or-privately-transmitted-content-are-the-sole-responsibility-of-the-person-from-whom-such-content-originated.-this-means-that-you-and-not-censo-are-entirely-responsible-for-all-content-that-you-upload-post-email-transmit-or-otherwise-make-available-through-the-service-your-content-and-other-users-of-the-service-and-not-censo-are-similarly-responsible-for-all-content-they-upload-post-email-transmit-or-otherwise-make-available-through-the-service-user-content.">All
information, data, data records, databases, text, software, music,
sounds, photographs, images, graphics, videos, messages, scripts, tags
and other materials accessible through the Service, whether publicly
posted or privately transmitted (“<u>Content</u>”), are the sole
responsibility of the person from whom such Content originated. This
means that you, and not Censo, are entirely responsible for all Content
that you upload, post, email, transmit or otherwise make available
through the Service (“<u>Your Content</u>”), and other users of the
Service, and not Censo, are similarly responsible for all Content they
upload, post, email, transmit or otherwise make available through the
Service (“<u>User Content</u>”).</h2>
<h2
id="censo-has-no-obligation-to-pre-screen-content-although-censo-reserves-the-right-in-its-sole-discretion-to-pre-screen-refuse-or-remove-any-content.-without-limiting-the-generality-of-the-foregoing-sentence-censo-shall-have-the-right-to-remove-any-content-that-violates-the-tou.">Censo
has no obligation to pre-screen Content, although Censo reserves the
right in its sole discretion to pre-screen, refuse or remove any
Content. Without limiting the generality of the foregoing sentence,
Censo shall have the right to remove any Content that violates the
TOU.</h2>
<h2
id="you-represent-and-warrant-that-i-you-have-all-necessary-rights-and-authority-to-grant-the-rights-set-forth-in-the-tou-with-respect-to-your-content-and-ii-your-content-does-not-violate-any-duty-of-confidentiality-owed-to-another-party-or-the-copyright-trademark-right-of-privacy-right-of-publicity-or-any-other-right-of-another-party.">You
represent and warrant that: (i) you have all necessary rights and
authority to grant the rights set forth in the TOU with respect to Your
Content; and (ii) Your Content does not violate any duty of
confidentiality owed to another party, or the copyright, trademark,
right of privacy, right of publicity or any other right of another
party.</h2>
<h1 id="rights-to-content">RIGHTS TO CONTENT</h1>
<h2
id="censo-does-not-claim-ownership-of-your-content.-however-you-hereby-grant-censo-and-its-service-providers-a-worldwide-royalty-free-non-exclusive-sublicensable-transferable-right-and-license-to-use-reproduce-modify-adapt-create-derivative-works-from-publicly-perform-publicly-display-distribute-make-and-have-made-your-content-in-any-form-and-any-medium-whether-now-known-or-later-developed-as-necessary-to-i-provide-access-to-and-use-of-the-service-to-you-and-other-users-and-ii-monitor-and-improve-the-service.-to-the-extent-you-have-made-any-portion-of-your-content-accessible-to-others-through-the-service-censo-may-continue-to-make-that-portion-of-your-content-accessible-to-others-through-the-service-even-after-1-termination-pursuant-to-section-18-or-2-you-have-deleted-your-account-or-that-portion-of-your-content-from-your-account.">Censo
does not claim ownership of Your Content. However, you hereby grant
Censo and its service providers a worldwide, royalty-free,
non-exclusive, sublicensable, transferable right and license to use,
reproduce, modify, adapt, create derivative works from, publicly
perform, publicly display, distribute, make and have made Your Content
(in any form and any medium, whether now known or later developed) as
necessary to (i) provide access to and use of the Service to you and
other users; and (ii) monitor and improve the Service. To the extent you
have made any portion of Your Content accessible to others through the
Service, Censo may continue to make that portion of Your Content
accessible to others through the Service even after: (1) termination
pursuant to Section 18; or (2) you have deleted your account or that
portion of Your Content from your account.</h2>
<h2
id="as-between-censo-and-you-censo-owns-all-rights-title-and-interest-including-all-intellectual-property-rights-in-the-service-and-all-improvements-enhancements-or-modifications-thereto-including-all-content-and-other-materials-therein-except-with-respect-to-your-content.-the-service-is-protected-by-united-states-and-international-copyright-patent-trademark-trade-secret-and-other-intellectual-property-laws-and-treaties.-censo-reserves-all-rights-not-expressly-granted-to-you.">As
between Censo and you, Censo owns all rights, title and interest
(including all intellectual property rights) in the Service and all
improvements, enhancements or modifications thereto, including all
Content and other materials therein (except with respect to Your
Content). The Service is protected by United States and international
copyright, patent, trademark, trade secret and other intellectual
property laws and treaties. Censo reserves all rights not expressly
granted to you.</h2>
<h2
id="you-acknowledge-and-agree-that-censo-may-collect-or-generate-aggregate-data-defined-below-in-connection-with-providing-you-with-access-to-and-use-of-the-service-and-you-hereby-grant-censo-a-perpetual-irrevocable-worldwide-royalty-free-fully-paid-up-non-exclusive-sublicensable-transferable-right-and-license-to-use-reproduce-modify-adapt-create-derivative-works-from-publicly-perform-publicly-display-distribute-make-and-have-made-aggregate-data-in-any-form-and-any-medium-whether-now-known-or-later-developed-for-any-lawful-purpose-consistent-with-the-censo-privacy-policy.-aggregate-data-means-your-content-or-any-data-generated-through-your-access-to-or-use-of-the-service-that-has-been-aggregated-or-de-identified-in-a-manner-that-does-not-reveal-any-personal-information-about-you-and-cannot-reasonably-be-used-to-identify-you-as-the-source-or-subject-of-such-data.">You
acknowledge and agree that Censo may collect or generate Aggregate Data
(defined below) in connection with providing you with access to and use
of the Service, and you hereby grant Censo a perpetual, irrevocable,
worldwide, royalty-free, fully-paid-up, non-exclusive, sublicensable,
transferable right and license to use, reproduce, modify, adapt, create
derivative works from, publicly perform, publicly display, distribute,
make and have made Aggregate Data (in any form and any medium, whether
now known or later developed) for any lawful purpose, consistent with
the Censo Privacy Policy. “<u>Aggregate Data</u>” means Your Content or
any data generated through your access to or use of the Service that has
been aggregated or de-identified in a manner that does not reveal any
personal information about you and cannot reasonably be used to identify
you as the source or subject of such data.</h2>
<h2
id="for-the-avoidance-of-doubt-the-seed-phrases-you-store-using-your-owner-app-are-stored-by-censo-in-encrypted-form.-censo-will-process-such-seed-phrases-as-part-of-providing-the-service-to-you-but-censo-will-only-do-so-with-the-seed-phrases-in-encrypted-form.">For
the avoidance of doubt, the Seed Phrases you store using your Owner App
are stored by Censo in encrypted form. Censo will process such Seed
Phrases as part of providing the Service to you, but Censo will only do
so with the Seed Phrases in encrypted form.</h2>
<h1 id="user-conduct">User CONDUCT</h1>
<p>In connection with your access to or use of the Service, you shall
not (subject to the limited rights expressly granted to you in Section
4):</p>
<h2
id="upload-post-email-transmit-or-otherwise-make-available-any-content-that-i-is-illegal-harmful-threatening-abusive-harassing-tortious-defamatory-vulgar-obscene-libelous-invasive-of-anothers-privacy-hateful-or-otherwise-objectionable-ii-any-applicable-law-defined-in-section-21-or-contractual-or-fiduciary-obligation-prohibits-you-from-making-available-such-as-confidential-or-proprietary-information-learned-as-part-of-an-employment-relationship-or-under-a-non-disclosure-agreement-iii-infringes-any-copyright-patent-trademark-trade-secret-or-other-proprietary-right-of-any-party-iv-consists-of-unsolicited-or-unauthorized-advertising-promotional-materials-junk-mail-spam-chain-letters-pyramid-schemes-commercial-electronic-messages-or-any-other-form-of-solicitation-v-contains-software-viruses-malware-or-any-other-code-files-or-programs-designed-to-interrupt-destroy-limit-the-functionality-of-make-unauthorized-modifications-to-or-perform-any-unauthorized-actions-through-any-software-or-hardware-or-vi-consists-of-information-that-you-know-or-have-reason-to-believe-is-false-or-inaccurate">upload,
post, email, transmit or otherwise make available any Content that: (i)
is illegal, harmful, threatening, abusive, harassing, tortious,
defamatory, vulgar, obscene, libelous, invasive of another's privacy,
hateful or otherwise objectionable; (ii) any Applicable Law (defined in
Section 21) or contractual or fiduciary obligation prohibits you from
making available (such as confidential or proprietary information
learned as part of an employment relationship or under a non-disclosure
agreement); (iii) infringes any copyright, patent, trademark, trade
secret or other proprietary right of any party; (iv) consists of
unsolicited or unauthorized advertising, promotional materials, junk
mail, spam, chain letters, pyramid schemes, commercial electronic
messages or any other form of solicitation; (v) contains software
viruses, malware or any other code, files or programs designed to
interrupt, destroy, limit the functionality of, make unauthorized
modifications to, or perform any unauthorized actions through any
software or hardware; or (vi) consists of information that you know or
have reason to believe is false or inaccurate;</h2>
<h2
id="use-reproduce-modify-adapt-create-derivative-works-from-publicly-perform-publicly-display-distribute-make-have-made-assign-pledge-transfer-or-otherwise-grant-rights-to-the-service-except-for-your-content">use,
reproduce, modify, adapt, create derivative works from, publicly
perform, publicly display, distribute, make, have made, assign, pledge,
transfer or otherwise grant rights to the Service (except for Your
Content);</h2>
<h2
id="reverse-engineer-disassemble-decompile-or-translate-or-otherwise-attempt-to-derive-the-source-code-architectural-framework-or-data-records-of-any-software-within-or-associated-with-the-service">reverse
engineer, disassemble, decompile or translate, or otherwise attempt to
derive the source code, architectural framework or data records of any
software within or associated with the Service;</h2>
<h2
id="remove-or-obscure-any-proprietary-notice-that-appears-within-the-service">remove
or obscure any proprietary notice that appears within the Service;</h2>
<h2
id="access-or-use-the-service-for-the-purpose-of-developing-marketing-selling-or-distributing-any-product-or-service-that-competes-with-or-includes-features-substantially-similar-to-the-service-or-any-other-products-or-services-offered-by-censo">access
or use the Service for the purpose of developing, marketing, selling or
distributing any product or service that competes with or includes
features substantially similar to the Service or any other products or
services offered by Censo;</h2>
<h2
id="rent-lease-lend-sell-or-sublicense-the-service-or-otherwise-provide-access-to-the-service-as-part-of-a-service-bureau-or-similar-fee-for-service-purpose">rent,
lease, lend, sell or sublicense the Service or otherwise provide access
to the Service as part of a service bureau or similar fee-for-service
purpose;</h2>
<h2
id="impersonate-any-person-or-entity-including-censo-personnel-or-falsely-state-or-otherwise-misrepresent-your-affiliation-with-any-person-or-entity">impersonate
any person or entity, including Censo personnel, or falsely state or
otherwise misrepresent your affiliation with any person or entity;</h2>
<h2
id="forge-or-manipulate-identifiers-headers-or-ip-addresses-to-disguise-the-origin-of-any-content-transmitted-through-the-service-or-the-location-from-which-it-originates">forge
or manipulate identifiers, headers or IP addresses to disguise the
origin of any Content transmitted through the Service or the location
from which it originates;</h2>
<h2
id="act-in-any-manner-that-negatively-affects-the-ability-of-other-users-to-access-or-use-the-service">act
in any manner that negatively affects the ability of other users to
access or use the Service;</h2>
<h2
id="take-any-action-that-imposes-an-unreasonable-or-disproportionately-heavy-load-on-the-service-or-its-infrastructure">take
any action that imposes an unreasonable or disproportionately heavy load
on the Service or its infrastructure;</h2>
<h2
id="interfere-with-or-disrupt-the-service-or-servers-or-networks-connected-to-the-service-or-disobey-any-requirements-procedures-policies-or-regulations-of-networks-connected-to-the-service">interfere
with or disrupt the Service or servers or networks connected to the
Service, or disobey any requirements, procedures, policies or
regulations of networks connected to the Service;</h2>
<h2
id="frame-or-utilize-any-framing-technique-to-enclose-the-service-or-any-portion-of-the-service-including-content">frame
or utilize any framing technique to enclose the Service or any portion
of the Service (including Content);</h2>
<h2
id="use-spiders-crawlers-robots-scrapers-automated-tools-or-any-other-similar-means-to-access-the-service-or-substantially-download-reproduce-or-archive-any-portion-of-the-service">use
spiders, crawlers, robots, scrapers, automated tools or any other
similar means to access the Service, or substantially download,
reproduce or archive any portion of the Service;</h2>
<h2
id="sell-share-transfer-trade-loan-or-exploit-for-any-commercial-purpose-any-portion-of-the-service-including-your-user-account-or-password-or">sell,
share, transfer, trade, loan or exploit for any commercial purpose any
portion of the Service, including your user account or password; or</h2>
<h2 id="violate-any-applicable-law.">violate any Applicable Law.</h2>
<h1 id="suggestions">Suggestions</h1>
<p>If you elect to provide or make available to Censo any suggestions,
comments, ideas, improvements or other feedback relating to the Service
(“<u>Suggestions</u>”), you hereby grant Censo a perpetual, irrevocable,
worldwide, royalty-free, fully-paid-up, non-exclusive, sublicensable,
transferable right and license to use, reproduce, modify, adapt, create
derivative works from, publicly perform, publicly display, distribute,
make or have made Suggestions in any form and any medium (whether now
known or later developed), without credit or compensation to you.</p>
<h1 id="dealings-with-third-parties">DEALINGS WITH THIRD PARTIES</h1>
<p>Your dealings with third parties (including other users or businesses
within the Service) who market, sell, buy or offer to sell or buy any
goods or services within or through the Service (collectively,
“<u>Third-Party Participants</u>”), including payment for and delivery
of such goods or services and any other terms, conditions, warranties or
representations associated with such dealings, are solely between you
and the applicable Third-Party Participant.</p>
<h1 id="modifications-to-the-service-and-beta-access">MODIFICATIONS TO
The Service and Beta Access</h1>
<h2
id="subject-to-any-additional-terms-censo-reserves-the-right-to-modify-suspend-or-discontinue-the-service-or-any-product-or-service-to-which-it-connects-with-or-without-notice-and-censo-shall-not-be-liable-to-you-or-any-third-party-for-any-such-modification-suspension-or-discontinuance.">Subject
to any Additional Terms, Censo reserves the right to modify, suspend or
discontinue the Service or any product or service to which it connects,
with or without notice, and Censo shall not be liable to you or any
third party for any such modification, suspension or
discontinuance.</h2>
<h2
id="censo-may-in-its-sole-discretion-from-time-to-time-develop-patches-bug-fixes-updates-upgrades-and-other-modifications-to-improve-the-performance-of-the-service-or-related-products-or-services-collectively-updates.-censo-may-develop-updates-that-require-installation-by-you-before-you-continue-to-access-or-use-the-service-or-related-products-or-services.-updates-may-also-be-automatically-installed-without-providing-any-additional-notice-to-you-or-receiving-any-additional-consent-from-you.-the-manner-in-which-updates-may-be-automatically-downloaded-and-installed-is-determined-by-settings-on-your-device-and-its-operating-system.">Censo
may, in its sole discretion, from time to time develop patches, bug
fixes, updates, upgrades and other modifications to improve the
performance of the Service or related products or services
(collectively, “<u>Updates</u>”). Censo may develop Updates that require
installation by you before you continue to access or use the Service or
related products or services. Updates may also be automatically
installed without providing any additional notice to you or receiving
any additional consent from you. The manner in which Updates may be
automatically downloaded and installed is determined by settings on your
device and its operating system.</h2>
<h2
id="the-service-may-experience-temporary-interruptions-due-to-technical-difficulties-maintenance-or-testing-or-updates-including-those-required-to-reflect-changes-in-relevant-laws-and-regulatory-requirements.-censo-has-no-obligation-to-provide-any-specific-content-through-the-service.">The
Service may experience temporary interruptions due to technical
difficulties, maintenance or testing, or Updates, including those
required to reflect changes in relevant laws and regulatory
requirements. Censo has no obligation to provide any specific content
through the Service.</h2>
<h2
id="your-access-to-or-use-of-the-service-may-be-part-of-a-beta-test-or-otherwise-involve-access-to-or-use-of-a-component-that-has-not-been-fully-tested-audited-or-validated-as-designated-within-the-service-each-a-beta-component.-you-acknowledge-and-agree-that-i-each-beta-component-is-a-beta-test-version-of-software-that-has-not-been-fully-tested-audited-or-validated-and-may-contain-bugs-defects-vulnerabilities-and-errors-collectively-errors-ii-the-beta-component-may-not-contain-functions-or-features-that-censo-may-make-available-as-part-of-a-general-availability-version-of-the-component-iii-censo-has-no-obligation-to-resolve-any-error-or-otherwise-provide-maintenance-or-support-for-the-beta-component-and-iv-you-access-or-use-a-beta-component-at-your-own-risk.">Your
access to or use of the Service may be part of a beta test or otherwise
involve access to or use of a component that has not been fully tested,
audited or validated, as designated within the Service (each, a “<u>Beta
Component</u>”). You acknowledge and agree that: (i) each Beta Component
is a beta test version of software that has not been fully tested,
audited or validated and may contain bugs, defects, vulnerabilities and
errors (collectively, “<u>Errors</u>”); (ii) the Beta Component may not
contain functions or features that Censo may make available as part of a
general availability version of the component; (iii) Censo has no
obligation to resolve any Error or otherwise provide maintenance or
support for the Beta Component; and (iv) you access or use a Beta
Component at your own risk.</h2>
<h1 id="indemnification">INDEMNIFICATION</h1>
<p>You agree that Censo shall have no liability for and you shall
indemnify, defend and hold Censo and its affiliates, and each of their
officers, directors, employees, agents, partners, business associates
and licensors (collectively, the “<u>Censo Parties</u>”) harmless from
and against any claim, demand, loss, damage, cost, liability and
expense, including reasonable attorneys’ fees, arising from or relating
to: (a) Your Content; (b) your violation of the TOU, Applicable Law, or
any rights (including intellectual property rights) of another party; or
(c) your access to or use of the Service.</p>
<h1 id="no-professional-advice-or-fiduciary-duties">No Professional
Advice or Fiduciary Duties</h1>
<p>All information provided in connection with your access to and use of
the Service should not and may not be construed as professional advice.
You should not take or omit any action in reliance on any information
obtained through the Service or that Censo makes available. You are
solely responsible for verifying the accuracy, completeness and
reliability of any such information. Before you make any financial,
legal or other decisions involving your access to or use of the Service,
you should seek independent professional advice from an individual who
is licensed and qualified in the area for which such advice would be
appropriate. The TOU is not intended to, and does not, create or impose
any fiduciary duties on Censo.</p>
<h1 id="disclaimer-of-warranties">DISCLAIMER OF WARRANTIES</h1>
<h2
id="your-use-of-the-service-is-at-your-sole-risk.-the-service-is-provided-on-an-as-is-and-as-available-basis-with-all-faults.-to-the-maximum-extent-permitted-by-applicable-law-the-censo-parties-expressly-disclaim-i-all-warranties-of-any-kind-whether-express-or-implied-or-arising-from-statute-course-of-dealing-usage-of-trade-or-otherwise-including-the-implied-warranties-of-merchantability-quality-fitness-for-a-particular-purpose-and-non-infringement-and-ii-any-loss-damage-or-other-liability-arising-from-or-relating-to-external-materials-third-party-components-or-third-party-participants-or-any-other-products-or-services-not-provided-by-censo.">YOUR
USE OF THE SERVICE IS AT YOUR SOLE RISK. THE SERVICE IS PROVIDED ON AN
“AS IS” AND “AS AVAILABLE” BASIS, WITH ALL FAULTS. TO THE MAXIMUM EXTENT
PERMITTED BY APPLICABLE LAW, THE CENSO PARTIES EXPRESSLY DISCLAIM: (i)
ALL WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED OR ARISING FROM
STATUTE, COURSE OF DEALING, USAGE OF TRADE OR OTHERWISE, INCLUDING THE
IMPLIED WARRANTIES OF MERCHANTABILITY, QUALITY, FITNESS FOR A PARTICULAR
PURPOSE, AND NON-INFRINGEMENT; AND (ii) ANY LOSS, DAMAGE OR OTHER
LIABILITY ARISING FROM OR RELATING TO EXTERNAL MATERIALS, THIRD-PARTY
COMPONENTS OR THIRD-PARTY PARTICIPANTS, OR ANY OTHER PRODUCTS OR
SERVICES NOT PROVIDED BY CENSO.</h2>
<h2
id="the-censo-parties-make-no-warranty-or-representation-that-i-the-service-will-meet-your-requirements-ii-access-to-the-service-will-be-uninterrupted-timely-secure-or-error-free-or-iii-the-information-and-any-results-that-may-be-obtained-from-access-to-or-use-of-the-service-will-be-accurate-reliable-current-or-complete.">THE
CENSO PARTIES MAKE NO WARRANTY OR REPRESENTATION THAT: (i) THE SERVICE
WILL MEET YOUR REQUIREMENTS; (ii) ACCESS TO THE SERVICE WILL BE
UNINTERRUPTED, TIMELY, SECURE OR ERROR-FREE; OR (iii) THE INFORMATION
AND ANY RESULTS THAT MAY BE OBTAINED FROM ACCESS TO OR USE OF THE
SERVICE WILL BE ACCURATE, RELIABLE, CURRENT OR COMPLETE.</h2>
<h2
id="the-service-relies-on-emerging-technologies-such-as-third-party-decentralized-exchanges.-some-services-are-subject-to-increased-risk-through-your-potential-misuse-of-things-such-as-publicprivate-key-cryptography.-by-using-the-service-you-acknowledge-and-accept-these-heightened-risks.-censo-shall-not-be-liable-for-the-failure-of-any-message-to-be-delivered-to-or-be-received-by-the-intended-recipient-through-your-access-to-or-use-of-service-or-for-the-diminution-of-value-of-any-digital-asset.">THE
SERVICE RELIES ON EMERGING TECHNOLOGIES SUCH AS THIRD-PARTY
DECENTRALIZED EXCHANGES. SOME SERVICES ARE SUBJECT TO INCREASED RISK
THROUGH YOUR POTENTIAL MISUSE OF THINGS SUCH AS PUBLIC/PRIVATE KEY
CRYPTOGRAPHY. BY USING THE SERVICE, YOU ACKNOWLEDGE AND ACCEPT THESE
HEIGHTENED RISKS. CENSO SHALL NOT BE LIABLE FOR THE FAILURE OF ANY
MESSAGE TO BE DELIVERED TO OR BE RECEIVED BY THE INTENDED RECIPIENT
THROUGH YOUR ACCESS TO OR USE OF SERVICE, OR FOR THE DIMINUTION OF VALUE
OF ANY DIGITAL ASSET.</h2>
<h2
id="for-the-avoidance-of-doubt-you-acknowledge-and-agree-that-you-will-not-be-able-to-access-or-use-your-owner-app-or-the-seed-phrases-stored-using-your-owner-app-if-i-you-do-not-have-an-active-valid-paid-subscription-ii-your-approvers-do-not-approve-your-access-to-the-owner-app-in-accordance-with-the-procedures-including-any-time-limitations-established-by-censo-or-iii-you-do-not-set-up-or-use-the-liveness-verification-functionality-properly.-in-each-such-case-you-will-not-be-able-to-access-or-use-your-owner-app-or-the-seed-phrases-stored-using-your-owner-app-in-which-case-you-may-not-be-able-to-access-digital-assets-stored-within-wallets-protected-using-the-applicable-seed-phrases.">FOR
THE AVOIDANCE OF DOUBT, YOU ACKNOWLEDGE AND AGREE THAT YOU WILL NOT BE
ABLE TO ACCESS OR USE YOUR OWNER APP OR THE SEED PHRASES STORED USING
YOUR OWNER APP IF: (i) YOU DO NOT HAVE AN ACTIVE, VALID PAID
SUBSCRIPTION; (ii) YOUR APPROVERS DO NOT APPROVE YOUR ACCESS TO THE
OWNER APP IN ACCORDANCE WITH THE PROCEDURES, INCLUDING ANY TIME
LIMITATIONS, ESTABLISHED BY CENSO; OR (iii) YOU DO NOT SET UP OR USE THE
LIVENESS VERIFICATION FUNCTIONALITY PROPERLY. IN EACH SUCH CASE, YOU
WILL NOT BE ABLE TO ACCESS OR USE YOUR OWNER APP OR THE SEED PHRASES
STORED USING YOUR OWNER APP, IN WHICH CASE YOU MAY NOT BE ABLE TO ACCESS
DIGITAL ASSETS STORED WITHIN WALLETS PROTECTED USING THE APPLICABLE SEED
PHRASES.</h2>
<h1 id="limitation-of-liability">LIMITATION OF LIABILITY</h1>
<h2
id="the-censo-parties-shall-not-be-liable-for-any-lost-profits-loss-of-or-loss-of-access-to-digital-assets-diminution-in-value-of-digital-assets-cost-of-cover-or-indirect-incidental-special-exemplary-punitive-or-consequential-damages-including-damages-arising-from-or-relating-to-any-type-or-manner-of-commercial-business-or-financial-loss-in-each-case-even-if-the-censo-parties-had-actual-or-constructive-knowledge-of-the-possibility-of-such-damages-and-regardless-of-whether-such-damages-were-foreseeable.-in-no-event-shall-the-censo-parties-total-liability-to-you-for-all-claims-arising-from-or-relating-to-the-tou-or-your-access-to-or-use-of-or-inability-to-access-or-use-the-service-exceed-the-greater-of-100-or-the-amount-paid-by-you-to-censo-if-any-for-access-to-or-use-of-the-service-during-the-six-months-immediately-preceding-the-date-on-which-the-applicable-claim-arose.">THE
CENSO PARTIES SHALL NOT BE LIABLE FOR ANY LOST PROFITS; LOSS OF, OR LOSS
OF ACCESS TO, DIGITAL ASSETS; DIMINUTION IN VALUE OF DIGITAL ASSETS;
COST OF COVER; OR INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, PUNITIVE OR
CONSEQUENTIAL DAMAGES, INCLUDING DAMAGES ARISING FROM OR RELATING TO ANY
TYPE OR MANNER OF COMMERCIAL, BUSINESS OR FINANCIAL LOSS, IN EACH CASE
EVEN IF THE CENSO PARTIES HAD ACTUAL OR CONSTRUCTIVE KNOWLEDGE OF THE
POSSIBILITY OF SUCH DAMAGES AND REGARDLESS OF WHETHER SUCH DAMAGES WERE
FORESEEABLE. IN NO EVENT SHALL THE CENSO PARTIES’ TOTAL LIABILITY TO YOU
FOR ALL CLAIMS ARISING FROM OR RELATING TO THE TOU OR YOUR ACCESS TO OR
USE OF (OR INABILITY TO ACCESS OR USE) THE SERVICE EXCEED THE GREATER OF
$100 OR THE AMOUNT PAID BY YOU TO CENSO (IF ANY) FOR ACCESS TO OR USE OF
THE SERVICE DURING THE SIX MONTHS IMMEDIATELY PRECEDING THE DATE ON
WHICH THE APPLICABLE CLAIM AROSE.</h2>
<h2
id="certain-state-laws-do-not-allow-limitations-on-implied-warranties-or-the-exclusion-or-limitation-of-certain-damages.-if-these-laws-apply-to-you-some-or-all-of-the-above-disclaimers-exclusions-or-limitations-may-not-apply-to-you-and-you-may-have-additional-rights.">CERTAIN
STATE LAWS DO NOT ALLOW LIMITATIONS ON IMPLIED WARRANTIES OR THE
EXCLUSION OR LIMITATION OF CERTAIN DAMAGES. IF THESE LAWS APPLY TO YOU,
SOME OR ALL OF THE ABOVE DISCLAIMERS, EXCLUSIONS OR LIMITATIONS MAY NOT
APPLY TO YOU, AND YOU MAY HAVE ADDITIONAL RIGHTS.</h2>
<h1 id="termination">TERMINATION</h1>
<h2
id="if-you-violate-the-tou-all-rights-granted-to-you-under-the-tou-terminate-immediately-with-or-without-notice-to-you.">If
you violate the TOU, all rights granted to you under the TOU terminate
immediately, with or without notice to you.</h2>
<h2
id="upon-termination-of-the-tou-for-any-reason-i-you-must-immediately-cease-accessing-or-using-the-service-ii-censo-may-remove-and-discard-your-content-and-delete-your-account-iii-any-provision-that-by-its-terms-is-intended-to-survive-the-termination-of-the-tou-will-survive-such-termination-and-iv-all-rights-granted-to-you-under-the-tou-immediately-terminate-but-all-other-provisions-will-survive-termination.">Upon
termination of the TOU for any reason: (i) you must immediately cease
accessing or using the Service; (ii) Censo may remove and discard Your
Content and delete your account; (iii) any provision that, by its terms,
is intended to survive the termination of the TOU will survive such
termination; and (iv) all rights granted to you under the TOU
immediately terminate, but all other provisions will survive
termination.</h2>
<h1 id="governing-law">Governing Law</h1>
<p>The TOU will be governed by and construed and enforced in accordance
with the United States Federal Arbitration Act, other applicable federal
laws, and the laws of the State of Texas, without regard to conflict of
laws principles. The United Nations Convention on Contracts for the
International Sale of Goods is specifically excluded from application to
the TOU.</p>
<h1 id="binding-arbitration-and-class-action-waiver">BINDING ARBITRATION
AND CLASS ACTION WAIVER</h1>
<h2
id="all-claims-defined-in-section-1b-will-be-resolved-by-binding-arbitration-rather-than-in-court-except-that-you-may-assert-claims-in-small-claims-court-if-your-claims-are-within-the-courts-jurisdiction.-there-is-no-judge-or-jury-in-arbitration-and-court-review-of-an-arbitration-award-is-limited.">ALL
CLAIMS (DEFINED IN SECTION 1(b)) WILL BE RESOLVED BY BINDING ARBITRATION
RATHER THAN IN COURT, EXCEPT THAT YOU MAY ASSERT CLAIMS IN SMALL CLAIMS
COURT IF YOUR CLAIMS ARE WITHIN THE COURT’S JURISDICTION. THERE IS NO
JUDGE OR JURY IN ARBITRATION, AND COURT REVIEW OF AN ARBITRATION AWARD
IS LIMITED.</h2>
<h2
id="the-arbitration-will-be-conducted-by-the-american-arbitration-association-aaa-under-its-then-applicable-commercial-arbitration-rules-or-as-appropriate-its-consumer-arbitration-rules.-the-aaas-rules-are-available-at-httpwww.adr.org.-the-arbitrator-will-among-other-things-have-the-power-to-rule-on-his-or-her-own-jurisdiction-including-any-objections-with-respect-to-the-existence-scope-or-validity-of-the-arbitration-agreement-or-to-the-arbitrability-of-any-claims.-payment-of-all-filing-administration-and-arbitrator-fees-will-be-governed-by-the-aaas-rules.-the-arbitration-will-be-conducted-in-the-english-language-by-a-single-independent-and-neutral-arbitrator.-for-any-hearing-conducted-in-person-as-part-of-the-arbitration-such-hearing-will-be-conducted-in-austin-texas-or-if-the-consumer-arbitration-rules-apply-another-location-reasonably-convenient-to-both-parties-with-due-consideration-of-their-ability-to-travel-and-other-pertinent-circumstances-as-determined-by-the-arbitrator.-the-decision-of-the-arbitrator-on-all-matters-relating-to-the-claim-will-be-final-and-binding.-judgment-on-the-arbitral-award-may-be-entered-in-any-court-of-competent-jurisdiction.">The
arbitration will be conducted by the American Arbitration Association
(AAA) under its then-applicable Commercial Arbitration Rules or, as
appropriate, its Consumer Arbitration Rules. The AAA’s rules are
available at <a href="http://www.adr.org/">http://www.adr.org/</a>. The
arbitrator will, among other things, have the power to rule on his or
her own jurisdiction, including any objections with respect to the
existence, scope, or validity of the arbitration agreement or to the
arbitrability of any Claims. Payment of all filing, administration and
arbitrator fees will be governed by the AAA’s rules. The arbitration
will be conducted in the English language by a single independent and
neutral arbitrator. For any hearing conducted in person as part of the
arbitration, such hearing will be conducted in Austin, Texas, or, if the
Consumer Arbitration Rules apply, another location reasonably convenient
to both parties with due consideration of their ability to travel and
other pertinent circumstances, as determined by the arbitrator. The
decision of the arbitrator on all matters relating to the Claim will be
final and binding. Judgment on the arbitral award may be entered in any
court of competent jurisdiction.</h2>
<h2
id="you-and-censo-each-i-agrees-that-all-claims-defined-in-section-1b-will-be-resolved-only-on-an-individual-basis-and-not-in-a-class-collective-consolidated-or-representative-action-arbitration-or-other-similar-process-and-ii-expressly-waives-any-right-to-have-a-claim-determined-or-resolved-on-a-class-collective-consolidated-or-representative-basis.-if-for-any-reason-the-provisions-of-the-preceding-sentence-are-held-to-be-invalid-or-unenforceable-in-a-case-in-which-class-collective-consolidated-or-representative-claims-have-been-asserted-the-provisions-of-this-section-20-requiring-binding-arbitration-will-likewise-be-unenforceable-and-null-and-void.-if-for-any-reason-a-claim-proceeds-in-court-rather-than-in-arbitration-you-and-censo-each-waives-any-right-to-a-jury-trial-and-agree-that-such-claim-will-be-brought-only-in-a-court-of-competent-jurisdiction-in-austin-texas.-you-hereby-submit-to-the-personal-jurisdiction-and-venue-of-such-courts-and-waive-any-objection-on-the-grounds-of-venue-forum-non-conveniens-or-any-similar-grounds-with-respect-to-any-such-claim.">YOU
AND CENSO EACH: (i) AGREES THAT ALL CLAIMS (DEFINED IN SECTION 1(b))
WILL BE RESOLVED ONLY ON AN INDIVIDUAL BASIS AND NOT IN A CLASS,
COLLECTIVE, CONSOLIDATED OR REPRESENTATIVE ACTION, ARBITRATION OR OTHER
SIMILAR PROCESS; AND (ii) EXPRESSLY WAIVES ANY RIGHT TO HAVE A CLAIM
DETERMINED OR RESOLVED ON A CLASS, COLLECTIVE, CONSOLIDATED OR
REPRESENTATIVE BASIS. IF FOR ANY REASON THE PROVISIONS OF THE PRECEDING
SENTENCE ARE HELD TO BE INVALID OR UNENFORCEABLE IN A CASE IN WHICH
CLASS, COLLECTIVE, CONSOLIDATED OR REPRESENTATIVE CLAIMS HAVE BEEN
ASSERTED, THE PROVISIONS OF THIS SECTION 20 REQUIRING BINDING
ARBITRATION WILL LIKEWISE BE UNENFORCEABLE AND NULL AND VOID. IF FOR ANY
REASON A CLAIM PROCEEDS IN COURT RATHER THAN IN ARBITRATION, YOU AND
CENSO EACH WAIVES ANY RIGHT TO A JURY TRIAL AND AGREE THAT SUCH CLAIM
WILL BE BROUGHT ONLY IN A COURT OF COMPETENT JURISDICTION IN AUSTIN,
TEXAS. YOU HEREBY SUBMIT TO THE PERSONAL JURISDICTION AND VENUE OF SUCH
COURTS AND WAIVE ANY OBJECTION ON THE GROUNDS OF VENUE, FORUM
<em>NON-CONVENIENS</em> OR ANY SIMILAR GROUNDS WITH RESPECT TO ANY SUCH
CLAIM.</h2>
<h2
id="notwithstanding-anything-to-the-contrary-you-and-censo-may-seek-injunctive-relief-and-any-other-equitable-remedies-from-any-court-of-competent-jurisdiction-to-protect-our-intellectual-property-rights-whether-in-aid-of-pending-or-independently-of-the-resolution-of-any-dispute-pursuant-to-the-arbitration-procedures-set-forth-in-this-section-20.">Notwithstanding
anything to the contrary, you and Censo may seek injunctive relief and
any other equitable remedies from any court of competent jurisdiction to
protect our intellectual property rights, whether in aid of, pending or
independently of the resolution of any dispute pursuant to the
arbitration procedures set forth in this Section 20.</h2>
<h2
id="if-censo-implements-any-material-change-to-this-section-20-such-change-will-not-apply-to-any-claim-for-which-you-provided-written-notice-to-censo-before-the-implementation-of-the-change.">If
Censo implements any material change to this Section 20, such change
will not apply to any Claim for which you provided written notice to
Censo before the implementation of the change.</h2>
<h1 id="legal-compliance">Legal Compliance</h1>
<h2
id="applicable-law-means-all-applicable-laws-and-regulations-including-anti-corruptionaml-laws-export-control-and-import-laws-and-the-prohibited-party-list.-anti-corruptionaml-laws-means-all-applicable-anti-corruption-know-your-customer-anti-bribery-anti-kickback-anti-money-laundering-anti-terrorist-financing-anti-fraud-anti-embezzlement-and-similar-laws-and-regulations-including-the-u.s.-foreign-corrupt-practices-act-of-1977-as-amended-15-u.s.c.-78dd-1-et-seq.-the-u.s.-travel-act-the-u.s.-domestic-bribery-statute-contained-in-18-u.s.c.-201-and-the-usa-patriot-act.-export-control-and-import-laws-means-all-applicable-export-control-and-import-laws-and-all-applicable-laws-governing-embargoes-sanctions-and-boycotts-including-the-arms-export-controls-act-of-1976-22-u.s.c.-ch.-39-the-international-emergency-economic-powers-act-50-u.s.c.-1701-et-seq.-the-trading-with-the-enemy-act-50-u.s.c.-app.-1-et-seq.-the-international-boycott-provisions-of-section-999-of-the-internal-revenue-code-the-international-traffic-in-arms-regulations-22-c.f.r.-120-et-seq.-the-export-administration-regulations-15-c.f.r.-730-et-seq.-the-laws-administered-by-the-office-of-foreign-assets-control-of-the-united-states-department-of-the-treasury-or-the-united-states-customs-and-border-protection-and-all-rules-regulations-and-executive-orders-relating-to-any-of-the-foregoing.-prohibited-party-list-means-any-u.s.-government-list-of-parties-with-whom-companies-and-other-entities-are-prohibited-from-transacting-business-including-the-specially-designated-nationals-and-blocked-persons-list-foreign-sanctions-evaders-list-sectoral-sanctions-identification-list-denied-persons-list-entity-list-and-unverified-list-each-as-may-be-maintained-and-updated-by-u.s.-treasury-departments-office-of-foreign-assets-control-or-the-bureau-of-industry-and-security-of-the-u.s.-department-of-commerce.">“<u>Applicable
Law</u>” means all applicable laws and regulations, including
Anti-Corruption/AML Laws, Export Control and Import Laws and the
Prohibited Party List. “<u>Anti-Corruption/AML Laws</u>” means all
applicable anti-corruption, “know your customer,” anti-bribery,
anti-kickback, anti-money laundering, anti-terrorist financing,
anti-fraud, anti-embezzlement and similar laws and regulations,
including the U.S. Foreign Corrupt Practices Act of 1977 as amended (15
U.S.C. §§78dd-1, <u>et</u> <u>seq</u>.), the U.S. Travel Act, the U.S.
Domestic Bribery Statute contained in 18 U.S.C. § 201, and the USA
PATRIOT Act. “<u>Export Control and Import Laws</u>” means all
applicable export control and import laws, and all applicable laws
governing embargoes, sanctions and boycotts, including the Arms Export
Controls Act of 1976 (22 U.S.C. Ch. 39); the International Emergency
Economic Powers Act (50 U.S.C. §§1701 <u>et</u> <u>seq</u>.); the
Trading with the Enemy Act (50 U.S.C. app. §§1 <u>et</u> <u>seq</u>.);
the International Boycott Provisions of Section 999 of the Internal
Revenue Code; the International Traffic in Arms Regulations (22 C.F.R.
§§120 <u>et</u> <u>seq</u>.); the Export Administration Regulations (15
C.F.R. §§730 <u>et</u> <u>seq</u>.); the laws administered by the Office
of Foreign Assets Control of the United States Department of the
Treasury or the United States Customs and Border Protection; and all
rules, regulations and executive orders relating to any of the
foregoing. “<u>Prohibited Party List</u>” means any U.S. government list
of parties with whom companies and other entities are prohibited from
transacting business, including the Specially Designated Nationals and
Blocked Persons List, Foreign Sanctions Evaders List, Sectoral Sanctions
Identification List, Denied Persons List, Entity List and Unverified
List, each as may be maintained and updated by U.S. Treasury
Department’s Office of Foreign Assets Control or the Bureau of Industry
and Security of the U.S. Department of Commerce.</h2>
<h2
id="you-shall-comply-with-all-applicable-laws-in-all-material-respects-in-connection-with-your-access-to-or-use-of-the-service.-without-limiting-the-generality-of-the-foregoing-you-understand-that-the-service-may-be-subject-to-export-control-and-import-laws-and-the-prohibited-party-list.-you-shall-not-access-or-use-the-service-in-violation-of-any-export-control-and-import-laws-and-you-represent-and-warrant-that-you-are-not-on-any-prohibited-party-list-whenever-you-access-or-use-the-service.-you-further-represent-and-warrant-that-you-have-legally-obtained-the-digital-assets-that-you-maintain-or-transfer-using-the-service-and-you-are-the-legal-owner-of-such-digital-assets-and-are-duly-authorized-to-engage-in-transactions-using-such-digital-assets-using-the-service.-you-shall-not-use-the-service-to-transmit-or-exchange-digital-assets-that-are-the-direct-or-indirect-proceeds-of-any-criminal-or-fraudulent-activity-including-terrorism-or-tax-evasion-nor-may-you-use-the-service-in-violation-of-any-anti-corruptionaml-laws.">You
shall comply with all Applicable Laws in all material respects in
connection with your access to or use of the Service. Without limiting
the generality of the foregoing, you understand that the Service may be
subject to Export Control and Import Laws and the Prohibited Party List.
You shall not access or use the Service in violation of any Export
Control and Import Laws, and you represent and warrant that you are not
on any Prohibited Party List whenever you access or use the Service. You
further represent and warrant that you have legally obtained the Digital
Assets that you maintain or transfer using the Service, and you are the
legal owner of such Digital Assets and are duly authorized to engage in
transactions using such Digital Assets using the Service. You shall not
use the Service to transmit or exchange Digital Assets that are the
direct or indirect proceeds of any criminal or fraudulent activity,
including terrorism or tax evasion, nor may you use the Service in
violation of any Anti-Corruption/AML Laws.</h2>
<h2
id="you-shall-not-provide-any-information-that-is-false-inaccurate-or-misleading-while-using-the-service-or-engage-in-any-activity-that-defrauds-censo-other-users-of-the-service-or-any-other-entity.">You
shall not provide any information that is false, inaccurate or
misleading while using the Service or engage in any activity that
defrauds Censo, other users of the Service, or any other entity.</h2>
<h1 id="united-states-government-entities">United States Government
Entities</h1>
<p>This section applies to access to or use of the Service by a branch
or agency of the United States Government. The Service includes
“commercial computer software” and “commercial computer software
documentation” as such terms are used in 48 C.F.R. 12.212 and qualifies
as “commercial items” as defined in 48 C.F.R. 2.101. Such items are
provided to the United States Government: (a) for acquisition by or on
behalf of civilian agencies, consistent with the policy set forth in 48
C.F.R. 12.212; or (b) for acquisition by or on behalf of units of the
Department of Defense, consistent with the policies set forth in 48
C.F.R. 227.7202-1 and 227.7202-3. The United States Government shall
acquire only those rights set forth in the TOU with respect to the such
items, and any access to or use of the Service by the United States
Government constitutes: (i) agreement by the United States Government
that such items are “commercial computer software” and “commercial
computer software documentation” as defined in this section; and (ii)
acceptance of the rights and obligations herein.</p>
<h1 id="no-third-party-beneficiaries">NO THIRD-PARTY BENEFICIARIES</h1>
<p>You acknowledge and agree that there are no third-party beneficiaries
to the TOU, except for the Censo Parties and Apple (as set forth in
Section 1(a)).</p>
<h1 id="procedure-for-making-claims-of-copyright-infringement">Procedure
for Making Claims of Copyright Infringement</h1>
<p>If you believe that your work has been made available through the
Service in a way that constitutes copyright infringement, please provide
Censo’s Agent for Notice of Copyright Claims the following information:
(a) a physical or electronic signature of a person authorized to act on
behalf of the owner of an exclusive right that is allegedly infringed;
(b) a description of the copyrighted work claimed to have been
infringed, or, if multiple copyrighted works are covered by a single
notification, a representative list of such works; (c) a description of
the material that you claim is infringing and where that material may be
accessed within the Service; (d) your address, telephone number and
email address; (e) a statement by you that you have a good-faith belief
that use of the material in the manner complained of is not authorized
by the copyright owner, its agent or the law; and (f) a statement from
you that the information in the notification is accurate and, under
penalty of perjury, that you are authorized to act on behalf of the
owner of an exclusive right that is allegedly infringed. Censo’s Agent
for Notice of Copyright Claims can be reached as follows:</p>
<blockquote>
<p>Censo, Inc.</p>
<p>Attn: Agent for Notice of Copyright Claims<br />
111 Congress Avenue, Suite 500</p>
</blockquote>
<p>Austin, TX 78701</p>
<blockquote>
<p>Phone:</p>
<p>Email: <a href="mailto:copyright@censo.co">copyright@censo.co</a></p>
</blockquote>
<h1 id="california-users-and-residents">California Users And
Residents</h1>
<p>In accordance with California Civil Code §1789.3, you may report
complaints to the Complaint Assistance Unit of the Division of Consumer
Services of the California Department of Consumer Affairs by contacting
such unit in writing at 1625 North Market Blvd., Suite N 112,
Sacramento, CA 95834, by telephone at (800) 952-5210, or as otherwise
set forth at <a
href="https://www.dca.ca.gov/about_us/contactus.shtml">https://www.dca.ca.gov/about_us/contactus.shtml</a>
(or a successful URL).</p>
<h1 id="general-provisions">GENERAL PROVISIONS</h1>
<p>The TOU (together with the Additional Terms) constitutes the entire
agreement between you and Censo concerning your access to and use of the
Service. It supersedes all prior and contemporaneous oral or written
negotiations and agreements between you and Censo with respect to such
subject matter. In the event of any conflict between or among the TOU
and any Additional Terms, the TOU will take precedence and govern. The
TOU may not be amended by you except in a writing executed by you and an
authorized representative of Censo. For the purposes of the TOU, the
words “such as,” “include,” “includes” and “including” will be deemed to
be followed by the words “without limitation.” You may not assign or
delegate any right or obligation under the TOU without the prior written
consent of Censo. Censo may assign or delegate any of its rights or
obligations under the TOU without your consent. The failure of Censo to
exercise or enforce any right or provision of the TOU will not
constitute a waiver of such right or provision. If any provision of the
TOU is held to be invalid or unenforceable under Applicable Law, then
such provision will be construed, limited, modified or, if necessary,
severed to the extent necessary to eliminate its invalidity or
unenforceability, without in any way affecting the remaining parts of
the TOU. Except with respect to your obligation to pay fees when due,
any prevention of or delay in performance by Censo hereunder due to any
act of god, fire, casualty, flood, war, strike, lock out, failure of
public utilities, injunction or any act, exercise, assertion or
requirement of any governmental entity, epidemic, pandemic, public
health crisis, destruction of production facilities, insurrection or any
other cause beyond Censo’s reasonable control will excuse the
performance of its obligations for a period equal to the duration of any
such prevention or delay.</p>

"""
}

#if DEBUG
#Preview {
    TermsOfUse(text: TermsOfUse.v0_2, onAccept: {
        debugPrint("Accepted!")
    })
}
#endif
