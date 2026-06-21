//
//  main.swift
//  Latissandra
//
//  Entry point. Runs as a menu-bar-only (.accessory) app — no dock icon.
//
//  Pass --probe to print a single CPU/RAM reading and exit (handy for verifying
//  the numbers without the GUI).
//

import Cocoa

if CommandLine.arguments.contains("--probe") {
    let cpu = CPUSampler()
    _ = cpu.sample()                       // prime baseline
    Thread.sleep(forTimeInterval: 0.5)     // let some ticks accumulate
    let cpuPercent = cpu.sample()
    let mem = MemorySampler().sample()

    print(String(format: "CPU: %.1f%%", cpuPercent))
    print(String(
        format: "RAM: %.2f / %.2f GB (%.1f%%)",
        Double(mem.usedBytes) / 1_073_741_824.0,
        Double(mem.totalBytes) / 1_073_741_824.0,
        mem.percent
    ))
    exit(0)
}

// Debug helpers for the "Open at Login" feature (the GUI exposes this as a checkbox).
if CommandLine.arguments.contains("--login-status") {
    print("login item status: \(LoginItem.statusDescription)")
    exit(0)
}
if CommandLine.arguments.contains("--login-enable") {
    let ok = LoginItem.setEnabled(true)
    print("enable -> \(ok ? "ok" : "failed"); status: \(LoginItem.statusDescription)")
    exit(0)
}
if CommandLine.arguments.contains("--login-disable") {
    let ok = LoginItem.setEnabled(false)
    print("disable -> \(ok ? "ok" : "failed"); status: \(LoginItem.statusDescription)")
    exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)   // menu bar only, no dock icon / app switcher entry

let delegate = AppDelegate()
app.delegate = delegate
app.run()
