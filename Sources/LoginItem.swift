//
//  LoginItem.swift
//  Latissandra
//
//  Wraps SMAppService (macOS 13+) so the app can register/unregister itself as a
//  login item — the same thing as adding it under System Settings → Login Items,
//  but toggled from our own menu. No network, no privileged helper.
//

import Foundation
import ServiceManagement

enum LoginItem {
    /// True when the app is currently set to open at login.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .enabled:          return "enabled"
        case .notRegistered:    return "notRegistered"
        case .notFound:         return "notFound"
        case .requiresApproval: return "requiresApproval"
        @unknown default:       return "unknown"
        }
    }

    /// Registers or unregisters the app as a login item.
    /// Returns false if macOS refused the change (user denied approval).
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
            return true
        } catch {
            NSLog("Latissandra: login item toggle failed: \(error.localizedDescription)")
            return false
        }
    }
}
