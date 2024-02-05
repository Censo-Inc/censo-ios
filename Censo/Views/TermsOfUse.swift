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
                    .accessibilityIdentifier("termsWebView")
                Divider()
            } else {

                Image("Files")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 130)

                Text("Terms of Use")
                    .font(.title2)
                    .fontWeight(.semibold)
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
                .accessibilityIdentifier("reviewTermsButton")
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
            .accessibilityIdentifier("acceptTermsButton")

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
    static let v0_3: String = """
<section class="legal-text">
<section id="terms-of-use"
class="legal-text---heading w-layout-blockcontainer legal---container w-container">
<h1 class="legal-text---heading">Terms of Use</h1>
<div class="divider">

</div>
<p>Last Revised: January 31, 2024</p>
<div class="legal---rich-text-block w-richtext">
<h2 class="legal---heading"
id="acceptance-of-terms">1.ACCEPTANCE OF TERMS</h2>
<p>(a) Censo, Inc. (“Censo”) provides access to and use of its websites
and certain solutions for storage and management of seed phrases used by
crypto wallet owners and related services (collectively, the “Service”),
subject to the terms and conditions in these Terms of Use (the “TOU”).
Censo may, in its sole discretion, update the TOU at any time. You can
access and review the most-current version of the TOU at the URL for
this page or by clicking on the “Terms of Use” link within the Service
or as otherwise made available by Censo.</p>
<p>(b) PLEASE REVIEW THE TOU CAREFULLY. IT IMPOSES BINDING ARBITRATION
AND A WAIVER OF CLASS ACTIONS. THE TOU REQUIRES BINDING ARBITRATION TO
RESOLVE ANY DISPUTE OR CLAIM ARISING FROM OR RELATING TO THE TOU OR YOUR
ACCESS TO OR USE OF THE SERVICE, INCLUDING THE VALIDITY, APPLICABILITY
OR INTERPRETATION OF THE TOU (EACH, A “CLAIM”). YOU AGREE THAT ANY CLAIM
WILL BE RESOLVED ONLY ON AN INDIVIDUAL BASIS AND NOT IN A CLASS,
COLLECTIVE, CONSOLIDATED OR REPRESENTATIVE ACTION, ARBITRATION OR OTHER
SIMILAR PROCESS. PLEASE REVIEW SECTION 21 CAREFULLY TO UNDERSTAND YOUR
RIGHTS AND OBLIGATIONS WITH RESPECT TO THE RESOLUTION OF ANY CLAIM.</p>
<p>(c) BY ACCESSING OR USING THE SERVICE, YOU AGREE TO BE BOUND BY THE
TOU, INCLUDING ANY UPDATES OR REVISIONS POSTED HERE OR OTHERWISE
COMMUNICATED TO YOU. IF YOU ARE ENTERING INTO THE TOU ON BEHALF OF A
COMPANY OR OTHER LEGAL ENTITY, YOU REPRESENT AND WARRANT THAT YOU ARE
AUTHORIZED AND LAWFULLY ABLE TO BIND SUCH ENTITY TO THE TOU, IN WHICH
CASE THE TERM “YOU” WILL REFER TO SUCH ENTITY. IF YOU DO NOT HAVE SUCH
AUTHORITY, OR IF YOU DO NOT AGREE WITH THE TERMS AND CONDITIONS OF THE
TOU, YOU MAY NOT ACCESS OR USE THE SERVICE, AND YOU MUST UNINSTALL ANY
COMPONENTS OF THE SERVICE FROM ANY DEVICE WITHIN YOUR CUSTODY OR
CONTROL.</p>
<p>(d) You represent and warrant that you are at least 18 years of age
or the age of majority in your jurisdiction, whichever is greater, and
of legal age to form a binding contract. You further represent and
warrant that you are not a person barred from accessing or using the
Service under the laws of your country of residence or any other
applicable jurisdiction.</p>
<h2 class="legal---heading"
id="other-agreements-and-terms">2.OTHER AGREEMENTS AND TERMS</h2>
<p>(a) In addition to the TOU, your access to and use of the Service are
further subject to the Censo Privacy Policy and any usage or other
policies relating to the Service posted or otherwise made available to
you by Censo, including any purchase, subscription or other similar
terms posted within the Service (the Privacy Policy and any such usage
or other policies, collectively, “Additional Terms”). The Additional
Terms are part of the TOU and are hereby incorporated by reference, and
you agree to be bound by the Additional Terms.</p>
<p>(b) You acknowledge and agree that: (i) by accessing or using the
Service, Censo may collect, use, disclose, store and process information
about you in accordance with the TOU, including any Additional Terms;
and (ii) technical processing and transmission of data, including Your
Content (defined in Section 9(a)), associated with the Service may
require transmissions over various networks and changes to conform and
adapt to technical requirements of connecting networks or devices.</p>
<h2 class="legal---heading" id="fees-and-taxes">3.FEES AND TAXES</h2>
<p>(a) You are solely responsible for any data, usage and other charges
assessed by mobile, cable, internet or other communications services
providers for your access to and use of the Service. Some features of
the Service are free to use, but fees may apply for subscriptions,
premium features and other components (“Paid Subscriptions”). If there
is a fee listed for any portion of the Service (including any Mobile
App, as defined in Section 4(a)), by accessing or using that portion,
you agree to pay the fee. Your access to the Service may be suspended or
terminated if you do not make payment in full when due. If you sign up
for a Paid Subscription, your Paid Subscription will automatically renew
at the conclusion of the then-current term unless you turn off
auto-renewal in accordance with the instructions provided by the
applicable app store through which you purchase the Paid Subscription.
Ceasing to access or use the Service or uninstalling a Mobile App will
not automatically cancel your Paid Subscription or turn off
auto-renewal. You must cancel your Paid Subscription or turn off
auto-renewal to end recurring charges. If you simply uninstall the
Mobile Apps without canceling your Paid Subscription or turning off
auto-renewal, the recurring charges for your Paid Subscription will
continue. Canceling a Paid Subscription or turning off auto-renewal will
not entitle you to a refund of any fees already paid, and previously
charged fees will not be pro-rated based upon cancellation.</p>
<p>(b) If you purchase a Paid Subscription through a third party, such
as through an in-app purchase processed by an app store, separate terms
and conditions with such third party may apply to your access or use of
the Service in addition to the TOU. Please contact the third party
regarding any refunds or to manage your Paid Subscription.</p>
<p>(c) Any and all amounts payable hereunder by you are exclusive of any
value-added, sales, use, excise or other similar taxes (collectively,
“Taxes”). You are solely responsible for paying all applicable Taxes,
except for any Taxes based upon Censo’s net income. If Censo has the
legal obligation to collect any Taxes, you shall reimburse Censo upon
invoice. Taxes, if applicable, are calculated based on the information
you provide and the applicable rate at the time of your monthly
charge.</p>
<h2 class="legal---heading"
id="access-to-and-use-of-the-service">4.ACCESS TO AND USE OF THE SERVICE</h2>
<p>(a) Subject to your compliance with the TOU, including all Additional
Terms, in all material respects, Censo grants you a limited,
non-exclusive, non-transferable, non-sublicensable, revocable right to:
(i) access and view pages within the Service; (ii) access and use any
online software, application and other similar component within the
Service, to the extent that the Service provides you with access to or
use of such component, but only in the form made accessible by Censo
within the Service; and (iii) install, run and operate mobile
applications that Censo makes available for accessing or using the
Service (each a, “Mobile App”) on a mobile device that you own or
control, but only in executable, machine-readable, object code form.</p>
<p>(b) Censo makes available Mobile Apps for the storage and management
of seed phrases (each, a “Seed Phrase”) used to access digital wallets
(each, a “Wallet”) through which tokens, cryptocurrencies and other
crypto or blockchain-based digital assets are stored (collectively,
“Digital Assets”). To store and manage Seed Phrases, you access and use
a version of the Mobile Apps for owners (the “Owner App”). Within the
Owner App, you may optionally assign third parties you trust to help
confirm that you are entitled to access the Seed Phrases stored using
your Owner App (each, an “Approver”).</p>
<p>(c) Approvers use a version of the Mobile App set up to perform
limited Approver functions (the “Approver App”). Use of the Approver App
is free and does not require a Paid Subscription. Although setting up
Approvers in the Owner App is optional, failing to do so may limit your
ability to recover access to your Seed Phrases stored using your Owner
App if you lose access to the app store account associated with your
access to and use of the Owner App (the “App Store Account”).</p>
<p><strong>5.OWNER APP MANAGEMENT</strong></p>
<p>(a) The Owner App allows you to store and manage up to 100 Seed
Phrases for free. Please note that while we do not currently offer a
premium version, we are continuously exploring ways to enhance the app's
features and functionalities. In the future, we may introduce a premium
subscription option that could provide additional benefits and expanded
capabilities for users who require more extensive Seed Phrase storage
and management solutions.</p>
<p>(b) Access to and use of the Owner App requires that you authenticate
your identity: (i) through 3D liveness verification, which may include
the use of face scans performed using your mobile device (“Liveness
Verification”); or (ii) by setting up a password (“Password
Verification”). If you do not set up or use the Liveness Verification or
Password Verification functionality properly, you will not be able to
access or use your Owner App or the Seed Phrases stored using your Owner
App, in which case you may not be able to access Digital Assets stored
within Wallets protected using the applicable Seed Phrases. With respect
to your use of Password Verification: (A) if you lose your password,
your password cannot be reset or recovered by Censo; and (B) you are
solely responsible for keeping, remembering and safeguarding your
password and any losses, including loss of Digital Assets, arising from
your failure to keep, remember or safeguard your password.</p>
<p>(c) If you access or use an Owner App to manage, store or access Seed
Phrases, you represent and warrant that you have proper authorization
from all parties with a legal interest in the Seed Phrases and the
Digital Assets stored within Wallets protected using the applicable Seed
Phrases to manage, store or access such Seed Phrases.</p>
<p>‍<strong>6.IOS MOBILE APPS</strong></p>
<p>(a) If any Mobile App is downloaded by you from the Apple Inc.
(“Apple”) App Store (each, an “iOS Mobile App”), the right set forth in
Section 4(a)(iii) with respect to such iOS Mobile App is further subject
to your compliance in all material respects with the terms and
conditions of the Usage Rules set forth in the Apple App Store Terms of
Service.</p>
<p>(b) With respect to any iOS Mobile App, you and Censo acknowledge and
agree that the TOU is concluded between you and Censo only, and not with
Apple, and Apple is not responsible for iOS Mobile Apps and the contents
thereof. Apple has no obligation whatsoever to furnish any maintenance
and support services with respect to iOS Mobile Apps. Censo, not Apple,
is responsible for addressing any claims from you or any third party
relating to iOS Mobile Apps or your possession and/or use of iOS Mobile
Apps, including product liability claims, any claim that iOS Mobile Apps
fail to conform to any applicable legal or regulatory requirement, and
claims arising under consumer protection or similar legislation. Apple
and Apple’s subsidiaries are third-party beneficiaries of the TOU with
respect to iOS Mobile Apps, and Apple shall have the right (and will be
deemed to have accepted the right) to enforce the TOU against you as a
third-party beneficiary hereof with respect to iOS Mobile Apps. Subject
to Section 15, Censo, not Apple, shall be solely responsible for the
investigation, defense, settlement and discharge of any intellectual
property infringement claim attributable to iOS Mobile Apps.</p>
<h2 class="legal---heading" id="third-party-components">7.THIRD-PARTY
COMPONENTS</h2>
<p>Some components of the Service may be provided with or incorporate
third-party components licensed under open-source license agreements or
other third-party license terms (collectively, “Third-Party
Components”). Third-Party Components are subject to separate terms and
conditions set forth in the respective license agreements relating to
such components. For more information about Third-Party Components,
please see <a
href="https://www.censo.co/legal/3rd-party">https://www.censo.co/legal/3rd-party</a>
.</p>
<p>8.EXTERNAL MATERIALS AND THIRD-PARTY SERVICES</p>
<p>The Service or users of the Service may provide links or other
connections to other websites or resources. Censo does not endorse and
is not responsible for any content, advertising, products, services or
other materials on or available through such sites or resources
(“External Materials”). External Materials are subject to different
terms of use and privacy policies. You are responsible for reviewing and
complying with such terms of use and privacy policies.</p>
<h2 class="legal---heading"
id="responsibility-for-content">9.RESPONSIBILITY FOR CONTENT</h2>
<p>(a) All information, data, data records, databases, text, software,
music, sounds, photographs, images, graphics, videos, messages, scripts,
tags and other materials accessible through the Service, whether
publicly posted or privately transmitted (“Content”), are the sole
responsibility of the person from whom such Content originated. This
means that you, and not Censo, are entirely responsible for all Content
that you upload, post, email, transmit or otherwise make available
through the Service (“Your Content”), and other users of the Service,
and not Censo, are similarly responsible for all Content they upload,
post, email, transmit or otherwise make available through the Service
(“User Content”).</p>
<p>(b) Censo has no obligation to pre-screen Content, although Censo
reserves the right in its sole discretion to pre-screen, refuse or
remove any Content. Without limiting the generality of the foregoing
sentence, Censo shall have the right to remove any Content that violates
the TOU.</p>
<p>(c) You represent and warrant that: (i) you have all necessary rights
and authority to grant the rights set forth in the TOU with respect to
Your Content; and (ii) Your Content does not violate any duty of
confidentiality owed to another party, or the copyright, trademark,
right of privacy, right of publicity or any other right of another
party.</p>
<p>10.RIGHTS TO CONTENT</p>
<p>(a) Censo does not claim ownership of Your Content. However, you
hereby grant Censo and its service providers a worldwide, royalty-free,
non-exclusive, sublicensable, transferable right and license to use,
reproduce, modify, adapt, create derivative works from, publicly
perform, publicly display, distribute, make and have made Your Content
(in any form and any medium, whether now known or later developed) as
necessary to (i) provide access to and use of the Service to you and
other users; and (ii) monitor and improve the Service. To the extent you
have made any portion of Your Content accessible to others through the
Service, Censo may continue to make that portion of Your Content
accessible to others through the Service even after: (1) termination
pursuant to Section 19; or (2) you have deleted your account or that
portion of Your Content from your account.</p>
<p>(b) As between Censo and you, Censo owns all rights, title and
interest (including all intellectual property rights) in the Service and
all improvements, enhancements or modifications thereto, including all
Content and other materials therein (except with respect to Your
Content). The Service is protected by United States and international
copyright, patent, trademark, trade secret and other intellectual
property laws and treaties. Censo reserves all rights not expressly
granted to you.</p>
<p>(c) You acknowledge and agree that Censo may collect or generate
Aggregate Data (defined below) in connection with providing you with
access to and use of the Service, and you hereby grant Censo a
perpetual, irrevocable, worldwide, royalty-free, fully-paid-up,
non-exclusive, sublicensable, transferable right and license to use,
reproduce, modify, adapt, create derivative works from, publicly
perform, publicly display, distribute, make and have made Aggregate Data
(in any form and any medium, whether now known or later developed) for
any lawful purpose, consistent with the Censo Privacy Policy. “Aggregate
Data” means Your Content or any data generated through your access to or
use of the Service that has been aggregated or de-identified in a manner
that does not reveal any personal information about you and cannot
reasonably be used to identify you as the source or subject of such
data.</p>
<p>(d) For the avoidance of doubt, the Seed Phrases you store using your
Owner App are stored by Censo in encrypted form. Censo will process such
Seed Phrases as part of providing the Service to you, but Censo will
only do so with the Seed Phrases in encrypted form.</p>
<p>11.USER CONDUCT</p>
<p>In connection with your access to or use of the Service, you shall
not (subject to the limited rights expressly granted to you in Section
4):</p>
<p>(a) upload, post, email, transmit or otherwise make available any
Content that: (i) is illegal, harmful, threatening, abusive, harassing,
tortious, defamatory, vulgar, obscene, libelous, invasive of another's
privacy, hateful or otherwise objectionable; (ii) any Applicable Law
(defined in Section 22) or contractual or fiduciary obligation prohibits
you from making available (such as confidential or proprietary
information learned as part of an employment relationship or under a
non-disclosure agreement); (iii) infringes any copyright, patent,
trademark, trade secret or other proprietary right of any party; (iv)
consists of unsolicited or unauthorized advertising, promotional
materials, junk mail, spam, chain letters, pyramid schemes, commercial
electronic messages or any other form of solicitation; (v) contains
software viruses, malware or any other code, files or programs designed
to interrupt, destroy, limit the functionality of, make unauthorized
modifications to, or perform any unauthorized actions through any
software or hardware; or (vi) consists of information that you know or
have reason to believe is false or inaccurate;</p>
<p>(b) use, reproduce, modify, adapt, create derivative works from,
publicly perform, publicly display, distribute, make, have made, assign,
pledge, transfer or otherwise grant rights to the Service (except for
Your Content);</p>
<p>(c) reverse engineer, disassemble, decompile or translate, or
otherwise attempt to derive the source code, architectural framework or
data records of any software within or associated with the Service;</p>
<p>(d) remove or obscure any proprietary notice that appears within the
Service;</p>
<p>(e) access or use the Service for the purpose of developing,
marketing, selling or distributing any product or service that competes
with or includes features substantially similar to the Service or any
other products or services offered by Censo;</p>
<p>(f) rent, lease, lend, sell or sublicense the Service or otherwise
provide access to the Service as part of a service bureau or similar
fee-for-service purpose;</p>
<p>(g) impersonate any person or entity, including Censo personnel, or
falsely state or otherwise misrepresent your affiliation with any person
or entity;</p>
<p>(h) forge or manipulate identifiers, headers or IP addresses to
disguise the origin of any Content transmitted through the Service or
the location from which it originates;</p>
<p>(i) act in any manner that negatively affects the ability of other
users to access or use the Service;</p>
<p>(j) take any action that imposes an unreasonable or
disproportionately heavy load on the Service or its infrastructure;</p>
<p>(k) interfere with or disrupt the Service or servers or networks
connected to the Service, or disobey any requirements, procedures,
policies or regulations of networks connected to the Service;</p>
<p>(l) frame or utilize any framing technique to enclose the Service or
any portion of the Service (including Content);</p>
<p>(m) use spiders, crawlers, robots, scrapers, automated tools or any
other similar means to access the Service, or substantially download,
reproduce or archive any portion of the Service;</p>
<p>(n) sell, share, transfer, trade, loan or exploit for any commercial
purpose any portion of the Service, including your user account or
password; or</p>
<p>(o) violate any Applicable Law.</p>
<h2 class="legal---heading" id="suggestions">12.SUGGESTIONS</h2>
<p>If you elect to provide or make available to Censo any suggestions,
comments, ideas, improvements or other feedback relating to the Service
(“Suggestions”), you hereby grant Censo a perpetual, irrevocable,
worldwide, royalty-free, fully-paid-up, non-exclusive, sublicensable,
transferable right and license to use, reproduce, modify, adapt, create
derivative works from, publicly perform, publicly display, distribute,
make or have made Suggestions in any form and any medium (whether now
known or later developed), without credit or compensation to you.</p>
<h2 class="legal---heading" id="dealings-with-third-parties">13.DEALINGS
WITH THIRD PARTIES</h2>
<p>Your dealings with third parties (including other users or businesses
within the Service) who market, sell, buy or offer to sell or buy any
goods or services within or through the Service (collectively,
“Third-Party Participants”), including payment for and delivery of such
goods or services and any other terms, conditions, warranties or
representations associated with such dealings, are solely between you
and the applicable Third-Party Participant.</p>
<h2 class="legal---heading"
id="modifications-to-the-service-and-beta-access">14.MODIFICATIONS TO
THE SERVICE AND BETA ACCESS</h2>
<p>(a) Subject to any Additional Terms, Censo reserves the right to
modify, suspend or discontinue the Service or any product or service to
which it connects, with or without notice, and Censo shall not be liable
to you or any third party for any such modification, suspension or
discontinuance.</p>
<p>(b) Censo may, in its sole discretion, from time to time develop
patches, bug fixes, updates, upgrades and other modifications to improve
the performance of the Service or related products or services
(collectively, “Updates”). Censo may develop Updates that require
installation by you before you continue to access or use the Service or
related products or services. Updates may also be automatically
installed without providing any additional notice to you or receiving
any additional consent from you. The manner in which Updates may be
automatically downloaded and installed is determined by settings on your
device and its operating system.</p>
<p>(c) The Service may experience temporary interruptions due to
technical difficulties, maintenance or testing, or Updates, including
those required to reflect changes in relevant laws and regulatory
requirements. Censo has no obligation to provide any specific content
through the Service.</p>
<p>(d) Your access to or use of the Service may be part of a beta test
or otherwise involve access to or use of a component that has not been
fully tested, audited or validated, as designated within the Service
(each, a “Beta Component”). You acknowledge and agree that: (i) each
Beta Component is a beta test version of software that has not been
fully tested, audited or validated and may contain bugs, defects,
vulnerabilities and errors (collectively, “Errors”); (ii) the Beta
Component may not contain functions or features that Censo may make
available as part of a general availability version of the component;
(iii) Censo has no obligation to resolve any Error or otherwise provide
maintenance or support for the Beta Component; and (iv) you access or
use a Beta Component at your own risk.</p>
<h2 class="legal---heading" id="indemnification">15.INDEMNIFICATION</h2>
<p>You agree that Censo shall have no liability for and you shall
indemnify, defend and hold Censo and its affiliates, and each of their
officers, directors, employees, agents, partners, business associates
and licensors (collectively, the “Censo Parties”) harmless from and
against any claim, demand, loss, damage, cost, liability and expense,
including reasonable attorneys’ fees, arising from or relating to: (a)
Your Content; (b) your violation of the TOU, Applicable Law, or any
rights (including intellectual property rights) of another party; or (c)
your access to or use of the Service.</p>
<h2 class="legal---heading"
id="no-professional-advice-or-fiduciary-duties">16.NO PROFESSIONAL
ADVICE OR FIDUCIARY DUTIES</h2>
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
<h2 class="legal---heading" id="disclaimer-of-warranties">17.DISCLAIMER
OF WARRANTIES</h2>
<p>(a) YOUR USE OF THE SERVICE IS AT YOUR SOLE RISK. THE SERVICE IS
PROVIDED ON AN “AS IS” AND “AS AVAILABLE” BASIS, WITH ALL FAULTS. TO THE
MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE CENSO PARTIES EXPRESSLY
DISCLAIM: (i) ALL WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED OR
ARISING FROM STATUTE, COURSE OF DEALING, USAGE OF TRADE OR OTHERWISE,
INCLUDING THE IMPLIED WARRANTIES OF MERCHANTABILITY, QUALITY, FITNESS
FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT; AND (ii) ANY LOSS,
DAMAGE OR OTHER LIABILITY ARISING FROM OR RELATING TO EXTERNAL
MATERIALS, THIRD-PARTY COMPONENTS OR THIRD-PARTY PARTICIPANTS, OR ANY
OTHER PRODUCTS OR SERVICES NOT PROVIDED BY CENSO.</p>
<p>(b) THE CENSO PARTIES MAKE NO WARRANTY OR REPRESENTATION THAT: (i)
THE SERVICE WILL MEET YOUR REQUIREMENTS; (ii) ACCESS TO THE SERVICE WILL
BE UNINTERRUPTED, TIMELY, SECURE OR ERROR-FREE; OR (iii) THE INFORMATION
AND ANY RESULTS THAT MAY BE OBTAINED FROM ACCESS TO OR USE OF THE
SERVICE WILL BE ACCURATE, RELIABLE, CURRENT OR COMPLETE.</p>
<p>(c) THE SERVICE RELIES ON EMERGING TECHNOLOGIES SUCH AS THIRD-PARTY
DECENTRALIZED EXCHANGES. SOME SERVICES ARE SUBJECT TO INCREASED RISK
THROUGH YOUR POTENTIAL MISUSE OF THINGS SUCH AS PUBLIC/PRIVATE KEY
CRYPTOGRAPHY. BY USING THE SERVICE, YOU ACKNOWLEDGE AND ACCEPT THESE
HEIGHTENED RISKS. CENSO SHALL NOT BE LIABLE FOR THE FAILURE OF ANY
MESSAGE TO BE DELIVERED TO OR BE RECEIVED BY THE INTENDED RECIPIENT
THROUGH YOUR ACCESS TO OR USE OF SERVICE, OR FOR THE DIMINUTION OF VALUE
OF ANY DIGITAL ASSET.</p>
<p>(d) FOR THE AVOIDANCE OF DOUBT, YOU ACKNOWLEDGE AND AGREE THAT YOU
WILL NOT BE ABLE TO ACCESS OR USE YOUR OWNER APP OR THE SEED PHRASES
STORED USING YOUR OWNER APP IF:; (i) YOUR APPROVERS DO NOT APPROVE YOUR
ACCESS TO THE OWNER APP IN ACCORDANCE WITH THE PROCEDURES, INCLUDING ANY
TIME LIMITATIONS, ESTABLISHED BY CENSO; OR (ii) YOU DO NOT SET UP OR USE
THE LIVENESS VERIFICATION FUNCTIONALITY PROPERLY. IN EACH SUCH CASE, YOU
WILL NOT BE ABLE TO ACCESS OR USE YOUR OWNER APP OR THE SEED PHRASES
STORED USING YOUR OWNER APP, IN WHICH CASE YOU MAY NOT BE ABLE TO ACCESS
DIGITAL ASSETS STORED WITHIN WALLETS PROTECTED USING THE APPLICABLE SEED
PHRASES.</p>
<h2 class="legal---heading" id="limitation-of-liability">18.LIMITATION
OF LIABILITY</h2>
<p>(a) THE CENSO PARTIES SHALL NOT BE LIABLE FOR ANY LOST PROFITS; LOSS
OF, OR LOSS OF ACCESS TO, DIGITAL ASSETS; DIMINUTION IN VALUE OF DIGITAL
ASSETS; COST OF COVER; OR INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
PUNITIVE OR CONSEQUENTIAL DAMAGES, INCLUDING DAMAGES ARISING FROM OR
RELATING TO ANY TYPE OR MANNER OF COMMERCIAL, BUSINESS OR FINANCIAL
LOSS, IN EACH CASE EVEN IF THE CENSO PARTIES HAD ACTUAL OR CONSTRUCTIVE
KNOWLEDGE OF THE POSSIBILITY OF SUCH DAMAGES AND REGARDLESS OF WHETHER
SUCH DAMAGES WERE FORESEEABLE. IN NO EVENT SHALL THE CENSO PARTIES’
TOTAL LIABILITY TO YOU FOR ALL CLAIMS ARISING FROM OR RELATING TO THE
TOU OR YOUR ACCESS TO OR USE OF (OR INABILITY TO ACCESS OR USE) THE
SERVICE EXCEED THE GREATER OF $100 OR THE AMOUNT PAID BY YOU TO CENSO
(IF ANY) FOR ACCESS TO OR USE OF THE SERVICE DURING THE SIX MONTHS
IMMEDIATELY PRECEDING THE DATE ON WHICH THE APPLICABLE CLAIM AROSE.</p>
<p>(b) CERTAIN STATE LAWS DO NOT ALLOW LIMITATIONS ON IMPLIED WARRANTIES
OR THE EXCLUSION OR LIMITATION OF CERTAIN DAMAGES. IF THESE LAWS APPLY
TO YOU, SOME OR ALL OF THE ABOVE DISCLAIMERS, EXCLUSIONS OR LIMITATIONS
MAY NOT APPLY TO YOU, AND YOU MAY HAVE ADDITIONAL RIGHTS.</p>
<h2 class="legal---heading" id="termination">19.TERMINATION</h2>
<p>(a) If you violate the TOU, all rights granted to you under the TOU
terminate immediately, with or without notice to you.</p>
<p>(b) Upon termination of the TOU for any reason: (i) you must
immediately cease accessing or using the Service; (ii) Censo may remove
and discard Your Content and delete your account; (iii) any provision
that, by its terms, is intended to survive the termination of the TOU
will survive such termination; and (iv) all rights granted to you under
the TOU immediately terminate, but all other provisions will survive
termination.</p>
<h2 class="legal---heading" id="governing-law">20.GOVERNING LAW</h2>
<p>The TOU will be governed by and construed and enforced in accordance
with the United States Federal Arbitration Act, other applicable federal
laws, and the laws of the State of Texas, without regard to conflict of
laws principles. The United Nations Convention on Contracts for the
International Sale of Goods is specifically excluded from application to
the TOU.</p>
<h2 class="legal---heading"
id="binding-arbitration-and-class-action-waiver">21.BINDING ARBITRATION
AND CLASS ACTION WAIVER</h2>
<p>(a) ALL CLAIMS (DEFINED IN SECTION 1(b)) WILL BE RESOLVED BY BINDING
ARBITRATION RATHER THAN IN COURT, EXCEPT THAT YOU MAY ASSERT CLAIMS IN
SMALL CLAIMS COURT IF YOUR CLAIMS ARE WITHIN THE COURT’S JURISDICTION.
THERE IS NO JUDGE OR JURY IN ARBITRATION, AND COURT REVIEW OF AN
ARBITRATION AWARD IS LIMITED.</p>
<p>(b) The arbitration will be conducted by the American Arbitration
Association (AAA) under its then-applicable Commercial Arbitration Rules
or, as appropriate, its Consumer Arbitration Rules. The AAA’s rules are
available at http://www.adr.org/. The arbitrator will, among other
things, have the power to rule on his or her own jurisdiction, including
any objections with respect to the existence, scope, or validity of the
arbitration agreement or to the arbitrability of any Claims. Payment of
all filing, administration and arbitrator fees will be governed by the
AAA’s rules. The arbitration will be conducted in the English language
by a single independent and neutral arbitrator. For any hearing
conducted in person as part of the arbitration, such hearing will be
conducted in Austin, Texas, or, if the Consumer Arbitration Rules apply,
another location reasonably convenient to both parties with due
consideration of their ability to travel and other pertinent
circumstances, as determined by the arbitrator. The decision of the
arbitrator on all matters relating to the Claim will be final and
binding. Judgment on the arbitral award may be entered in any court of
competent jurisdiction.</p>
<p>(c) YOU AND CENSO EACH: (i) AGREES THAT ALL CLAIMS (DEFINED IN
SECTION 1(b)) WILL BE RESOLVED ONLY ON AN INDIVIDUAL BASIS AND NOT IN A
CLASS, COLLECTIVE, CONSOLIDATED OR REPRESENTATIVE ACTION, ARBITRATION OR
OTHER SIMILAR PROCESS; AND (ii) EXPRESSLY WAIVES ANY RIGHT TO HAVE A
CLAIM DETERMINED OR RESOLVED ON A CLASS, COLLECTIVE, CONSOLIDATED OR
REPRESENTATIVE BASIS. IF FOR ANY REASON THE PROVISIONS OF THE PRECEDING
SENTENCE ARE HELD TO BE INVALID OR UNENFORCEABLE IN A CASE IN WHICH
CLASS, COLLECTIVE, CONSOLIDATED OR REPRESENTATIVE CLAIMS HAVE BEEN
ASSERTED, THE PROVISIONS OF THIS SECTION 21 REQUIRING BINDING
ARBITRATION WILL LIKEWISE BE UNENFORCEABLE AND NULL AND VOID. IF FOR ANY
REASON A CLAIM PROCEEDS IN COURT RATHER THAN IN ARBITRATION, YOU AND
CENSO EACH WAIVES ANY RIGHT TO A JURY TRIAL AND AGREE THAT SUCH CLAIM
WILL BE BROUGHT ONLY IN A COURT OF COMPETENT JURISDICTION IN AUSTIN,
TEXAS. YOU HEREBY SUBMIT TO THE PERSONAL JURISDICTION AND VENUE OF SUCH
COURTS AND WAIVE ANY OBJECTION ON THE GROUNDS OF VENUE, FORUM
NON-CONVENIENS OR ANY SIMILAR GROUNDS WITH RESPECT TO ANY SUCH
CLAIM.</p>
<p>(d) Notwithstanding anything to the contrary, you and Censo may seek
injunctive relief and any other equitable remedies from any court of
competent jurisdiction to protect our intellectual property rights,
whether in aid of, pending or independently of the resolution of any
dispute pursuant to the arbitration procedures set forth in this Section
21.</p>
<p>(e) If Censo implements any material change to this Section 21, such
change will not apply to any Claim for which you provided written notice
to Censo before the implementation of the change.</p>
<h2 class="legal---heading" id="legal-compliance">22.LEGAL
COMPLIANCE</h2>
<p>(a) “Applicable Law” means all applicable laws and regulations,
including Anti-Corruption/AML Laws, Export Control and Import Laws and
the Prohibited Party List. “Anti-Corruption/AML Laws” means all
applicable anti-corruption, “know your customer,” anti-bribery,
anti-kickback, anti-money laundering, anti-terrorist financing,
anti-fraud, anti-embezzlement and similar laws and regulations,
including the U.S. Foreign Corrupt Practices Act of 1977 as amended (15
U.S.C. §§78dd-1, et seq.), the U.S. Travel Act, the U.S. Domestic
Bribery Statute contained in 18 U.S.C. § 201, and the USA PATRIOT Act.
“Export Control and Import Laws” means all applicable export control and
import laws, and all applicable laws governing embargoes, sanctions and
boycotts, including the Arms Export Controls Act of 1976 (22 U.S.C. Ch.
39); the International Emergency Economic Powers Act (50 U.S.C. §§1701
et seq.); the Trading with the Enemy Act (50 U.S.C. app. §§1 et seq.);
the International Boycott Provisions of Section 999 of the Internal
Revenue Code; the International Traffic in Arms Regulations (22 C.F.R.
§§120 et seq.); the Export Administration Regulations (15 C.F.R. §§730
et seq.); the laws administered by the Office of Foreign Assets Control
of the United States Department of the Treasury or the United States
Customs and Border Protection; and all rules, regulations and executive
orders relating to any of the foregoing. “Prohibited Party List” means
any U.S. government list of parties with whom companies and other
entities are prohibited from transacting business, including the
Specially Designated Nationals and Blocked Persons List, Foreign
Sanctions Evaders List, Sectoral Sanctions Identification List, Denied
Persons List, Entity List and Unverified List, each as may be maintained
and updated by U.S. Treasury Department’s Office of Foreign Assets
Control or the Bureau of Industry and Security of the U.S. Department of
Commerce.</p>
<p>(b) You shall comply with all Applicable Laws in all material
respects in connection with your access to or use of the Service.
Without limiting the generality of the foregoing, you understand that
the Service may be subject to Export Control and Import Laws and the
Prohibited Party List. You shall not access or use the Service in
violation of any Export Control and Import Laws, and you represent and
warrant that you are not on any Prohibited Party List whenever you
access or use the Service. You further represent and warrant that you
have legally obtained the Digital Assets that you maintain or transfer
using the Service, and you are the legal owner of such Digital Assets
and are duly authorized to engage in transactions using such Digital
Assets using the Service. You shall not use the Service to transmit or
exchange Digital Assets that are the direct or indirect proceeds of any
criminal or fraudulent activity, including terrorism or tax evasion, nor
may you use the Service in violation of any Anti-Corruption/AML
Laws.</p>
<p>(c) You shall not provide any information that is false, inaccurate
or misleading while using the Service or engage in any activity that
defrauds Censo, other users of the Service, or any other entity.</p>
<h2 class="legal---heading"
id="united-states-government-entities">23.UNITED STATES GOVERNMENT
ENTITIES</h2>
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
<h2 class="legal---heading" id="no-third-party-beneficiaries">24.NO
THIRD-PARTY BENEFICIARIES</h2>
<p>You acknowledge and agree that there are no third-party beneficiaries
to the TOU, except for the Censo Parties and Apple (as set forth in
Section 4(b)).</p>
<h2 class="legal---heading"
id="procedure-for-making-claims-of-copyright-infringement">25.PROCEDURE
FOR MAKING CLAIMS OF COPYRIGHT INFRINGEMENT</h2>
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
<p>Censo, Inc.<br />
Attn: Agent for Notice of Copyright Claims<br />
111 Congress Avenue, Suite 500<br />
Austin, TX 78701<br />
Phone: ‪‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬646-688-4722‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬‬<br />
Email: copyright@censo.co</p>
<h2 class="legal---heading"
id="california-users-and-residents">26.CALIFORNIA USERS AND
RESIDENTS</h2>
<p>In accordance with California Civil Code §1789.3, you may report
complaints to the Complaint Assistance Unit of the Division of Consumer
Services of the California Department of Consumer Affairs by contacting
such unit in writing at 1625 North Market Blvd., Suite N 112,
Sacramento, CA 95834, by telephone at (800) 952-5210, or as otherwise
set forth at https://www.dca.ca.gov/about_us/contactus.shtml (or a
successful URL).</p>
<h2 class="legal---heading" id="general-provisions">27.GENERAL
PROVISIONS</h2>
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
<p>‍</p>
<p>‍</p>
</div>
</section>
</section>

"""
}

#if DEBUG
#Preview {
    TermsOfUse(text: TermsOfUse.v0_3, onAccept: {
        debugPrint("Accepted!")
    }).foregroundColor(.Censo.primaryForeground)
}
#endif
