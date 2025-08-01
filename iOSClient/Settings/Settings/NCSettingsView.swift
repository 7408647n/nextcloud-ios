//
//  NCSettingsView.swift
//  Nextcloud
//
//  Created by Aditya Tyagi on 03/03/24.
//  Created by Marino Faggiana on 30/05/24.
//  Copyright © 2024 Marino Faggiana. All rights reserved.
//
//  Author Aditya Tyagi <adityagi02@yahoo.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import SwiftUI
import NextcloudKit

/// Settings view for Nextcloud
struct NCSettingsView: View {
    /// State to control the visibility of the acknowledgements view
    @State private var showAcknowledgements = false
    /// State to control the visibility of the passcode view
    @State private var showPasscode = false
    /// State to contorl the visibility of the change passcode view
    @State private var showChangePasscode = false
    /// State to control the visibility of the Policy view
    @State private var showBrowser = false
    /// State to control the visibility of the Source Code  view
    @State private var showSourceCode = false
    /// Object of ViewModel of this view
    @ObservedObject var model: NCSettingsModel

    var capabilities: NKCapabilities.Capabilities {
        NCNetworking.shared.capabilities[model.controller?.account ?? ""] ?? NKCapabilities.Capabilities()
    }

    var body: some View {
        Form {
            /// `Auto Upload` Section
            Section(content: {
                NavigationLink(destination: LazyView {
                    NCAutoUploadView(model: NCAutoUploadModel(controller: model.controller), albumModel: AlbumModel(controller: model.controller))
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                        Text(NSLocalizedString("_settings_autoupload_", comment: ""))
                    }
                }
            }, footer: {
                Text(NSLocalizedString("_autoupload_description_", comment: ""))
            })
            /// `Privacy` Section
            Section(content: {
                Button(action: {
                    showPasscode.toggle()
                }, label: {
                    HStack {
                        Image(systemName: model.isLockActive ? "lock" : "lock.open")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                            .frame(width: 20, height: 20)
                            .opacity(NCBrandOptions.shared.enforce_passcode_lock ? 0.5 : 1)
                        Text(model.isLockActive ? NSLocalizedString("_lock_active_", comment: "") : NSLocalizedString("_lock_not_active_", comment: ""))
                    }
                })
                .tint(Color(NCBrandColor.shared.textColor))
                .disabled(NCBrandOptions.shared.enforce_passcode_lock)
            }, header: {
                Text(NSLocalizedString("_privacy_", comment: ""))
            }, footer: {
                if NCBrandOptions.shared.enforce_passcode_lock {
                    Text(NSLocalizedString("_lock_cannot_disable_mdm_", comment: ""))
                }
            })

            if model.isLockActive {
                Section(content: {
                    Group {
                        // Change passcode
                        Button(action: {
                            showChangePasscode.toggle()
                        }, label: {
                            VStack {
                                Text(NSLocalizedString("_change_lock_passcode_", comment: ""))
                                    .tint(Color(NCBrandColor.shared.textColor))
                            }
                        })
                        /// Enable Touch ID
                        Toggle(NSLocalizedString("_enable_touch_face_id_", comment: ""), isOn: $model.enableTouchID)
                            .onChange(of: model.enableTouchID) { _ in
                                model.updateTouchIDSetting()
                            }

                        if !NCBrandOptions.shared.enforce_passcode_lock {
                            /// Do not ask for passcode on startup
                            Toggle(NSLocalizedString("_lock_protection_no_screen_", comment: ""), isOn: $model.lockScreen)
                                .onChange(of: model.lockScreen) { _ in
                                    model.updateLockScreenSetting()
                                }
                        }

                        /// Reset app wrong attempts
                        Toggle(NSLocalizedString("_reset_wrong_passcode_option_", comment: ""), isOn: $model.resetWrongAttempts)
                            .onChange(of: model.resetWrongAttempts) { _ in
                                model.updateResetWrongAttemptsSetting()
                            }
                    }
                }, footer: {
                    Text(String(format: NSLocalizedString("_reset_wrong_passcode_desc_", comment: ""), NCBrandOptions.shared.resetAppPasscodeAttempts))
                })
                .tint(Color(NCBrandColor.shared.getElement(account: model.session.account)))
            }

            if !NCBrandOptions.shared.enforce_privacyScreenEnabled {
                Section {
                    /// Splash screen when app inactive
                    Toggle(NSLocalizedString("_privacy_screen_", comment: ""), isOn: $model.privacyScreen)
                        .onChange(of: model.privacyScreen) { _ in
                            model.updatePrivacyScreenSetting()
                        }
                }
                .tint(Color(NCBrandColor.shared.getElement(account: model.session.account)))
            }

            /// Display
            Section(header: Text(NSLocalizedString("_display_", comment: "")), content: {
                NavigationLink(destination: LazyView {
                    NCDisplayView(model: NCDisplayModel(controller: model.controller))
                }) {
                    HStack {
                        Image(systemName: "sun.max.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                        Text(NSLocalizedString("_display_", comment: ""))
                    }
                }
            })
            /// Calender & Contacts
            if !NCBrandOptions.shared.disable_mobileconfig {
                Section(content: {
                    Button(action: {
                        model.getConfigFiles()
                    }, label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                            Text(NSLocalizedString("_mobile_config_", comment: ""))
                        }
                    })
                    .tint(Color(NCBrandColor.shared.textColor))
                }, header: {
                    Text(NSLocalizedString("_calendar_contacts_", comment: ""))
                }, footer: {
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString("_calendar_contacts_footer_warning_", comment: ""))
                        Spacer()
                        Text(NSLocalizedString("_calendar_contacts_footer_", comment: ""))
                    }

                })
            }
            /// Users
            Section(content: {
                Toggle(NSLocalizedString("_settings_account_request_", comment: ""), isOn: $model.accountRequest)
                    .tint(Color(NCBrandColor.shared.getElement(account: model.session.account)))
                    .onChange(of: model.accountRequest, perform: { _ in
                        model.updateAccountRequest()
                    })
            }, header: {
                Text(NSLocalizedString("_users_", comment: ""))
            }, footer: {
                Text(NSLocalizedString("_users_footer_", comment: ""))
            })
            /// E2EEncryption` Section
            if capabilities.e2EEEnabled && NCGlobal.shared.e2eeVersions.contains(capabilities.e2EEApiVersion) {
                E2EESection(model: model)
            }
            /// `Advanced` Section
            Section {
                NavigationLink(destination: LazyView {
                    NCSettingsAdvancedView(model: NCSettingsAdvancedModel(controller: model.controller), showExitAlert: false, showCacheAlert: false)
                }) {
                    HStack {
                        Image(systemName: "gear")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                        Text(NSLocalizedString("_advanced_", comment: ""))
                    }
                }
            }
            /// `Information` Section
            Section(header: Text(NSLocalizedString("_information_", comment: "")), content: {
                // Acknowledgements
                Button(action: {
                    showAcknowledgements.toggle()
                }, label: {
                    HStack {
                        Image("acknowledgements")
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 25, height: 25)
                            .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                        Text(NSLocalizedString("_acknowledgements_", comment: ""))
                    }
                })
                .tint(Color(NCBrandColor.shared.textColor))
                .sheet(isPresented: $showAcknowledgements) {
                    NCAcknowledgementsView(browserTitle: NSLocalizedString("_acknowledgements_", comment: ""))
                }
                /// Terms & Privacy Conditions
                Button(action: {
                    showBrowser.toggle()
                }, label: {
                    HStack {
                        Image(systemName: "shield.checkerboard")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                        Text(NSLocalizedString("_privacy_legal_", comment: ""))
                    }
                })
                .tint(Color(NCBrandColor.shared.textColor))
                .sheet(isPresented: $showBrowser) {
                    NCBrowserWebView(urlBase: URL(string: NCBrandOptions.shared.privacy)!, browserTitle: NSLocalizedString("_privacy_legal_", comment: ""))
                }
                /// Source Code Nextcloud App
                if !NCBrandOptions.shared.disable_source_code_in_settings {
                    Button(action: {
                        showSourceCode.toggle()
                    }, label: {
                        HStack {
                            Image("gitHub")
                                .resizable()
                                .renderingMode(.template)
                                .frame(width: 25, height: 25)
                                .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                            Text(NSLocalizedString("_source_code_", comment: ""))
                        }
                    })
                    .tint(Color(NCBrandColor.shared.textColor))
                    .sheet(isPresented: $showSourceCode) {
                        NCBrowserWebView(urlBase: URL(string: NCBrandOptions.shared.sourceCode)!, browserTitle: NSLocalizedString("_source_code_", comment: ""))
                    }
                }
            })
            /// `Watermark` Section
            Section(content: {
            }, footer: {
                Text(model.footerApp + model.footerServer + model.footerSlogan)
            })
        }
        .sheet(isPresented: $showPasscode) {
            SetupPasscodeView(isLockActive: $model.isLockActive)
        }
        .sheet(isPresented: $showChangePasscode) {
            SetupPasscodeView(isLockActive: $model.isLockActive, changePasscode: true)
        }
        .navigationBarTitle(NSLocalizedString("_settings_", comment: ""))
        .defaultViewModifier(model)
    }
}

struct E2EESection: View {
    @ObservedObject var model: NCSettingsModel

    var body: some View {
        Section(header: Text(NSLocalizedString("_e2e_settings_title_", comment: "")), content: {
            NavigationLink(destination: LazyView {
                NCManageE2EEView(model: NCManageE2EE(controller: model.controller))
            }) {
                HStack {
                    Image(systemName: "lock")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                    Text(NSLocalizedString("_e2e_settings_", comment: ""))
                }
            }
        })
    }
}

#Preview {
    NCSettingsView(model: NCSettingsModel(controller: nil))
}
