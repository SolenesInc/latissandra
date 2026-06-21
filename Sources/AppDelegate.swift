//
//  AppDelegate.swift
//  Latissandra
//
//  Owns the menu bar item and refreshes it on a timer.
//

import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?

    private let cpu = CPUSampler()
    private let memory = MemorySampler()

    private let refreshInterval: TimeInterval = 2.0

    private let cpuDetail = NSMenuItem(title: "CPU: …", action: nil, keyEquivalent: "")
    private let memDetail = NSMenuItem(title: "Memory: …", action: nil, keyEquivalent: "")
    private let loginMenuItem = NSMenuItem(title: "Open at Login", action: nil, keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            // Monospaced digits so the width doesn't jitter as numbers change.
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            button.title = "Latissandra…"
        }

        buildMenu()

        _ = cpu.sample()   // prime the CPU baseline
        refresh()

        let timer = Timer(timeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func buildMenu() {
        let menu = NSMenu()
        menu.delegate = self

        cpuDetail.isEnabled = false
        memDetail.isEnabled = false
        menu.addItem(cpuDetail)
        menu.addItem(memDetail)
        menu.addItem(.separator())

        loginMenuItem.action = #selector(toggleLogin(_:))
        loginMenuItem.target = self
        menu.addItem(loginMenuItem)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Latissandra", action: #selector(quit(_:)), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        updateLoginMenuItem()
    }

    @objc private func toggleLogin(_ sender: NSMenuItem) {
        let desired = !LoginItem.isEnabled
        if !LoginItem.setEnabled(desired) {
            let alert = NSAlert()
            alert.messageText = "Couldn't update Login Items"
            alert.informativeText = "macOS refused the change. You can set it manually in System Settings → General → Login Items."
            alert.runModal()
        }
        updateLoginMenuItem()
    }

    private func updateLoginMenuItem() {
        loginMenuItem.state = LoginItem.isEnabled ? .on : .off
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    private func refresh() {
        let cpuPercent = cpu.sample()
        let mem = memory.sample()

        statusItem.button?.title = String(format: "CPU %.0f%% · RAM %.0f%%", cpuPercent, mem.percent)

        cpuDetail.title = String(format: "CPU: %.0f%%", cpuPercent)
        memDetail.title = String(
            format: "Memory: %@ / %@ (%.0f%%)",
            Self.gigabytes(mem.usedBytes),
            Self.gigabytes(mem.totalBytes),
            mem.percent
        )
    }

    private static func gigabytes(_ bytes: UInt64) -> String {
        String(format: "%.1f GB", Double(bytes) / 1_073_741_824.0)
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        updateLoginMenuItem()
        refresh()
    }
}
