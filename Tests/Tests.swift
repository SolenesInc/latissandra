//
//  Tests.swift
//  Latissandra
//
//  A dependency-free test runner (no XCTest/SwiftPM, to match the swiftc build).
//  Compiled together with the sampler sources by tools/test.sh. Asserts the
//  invariants we actually care about; exits non-zero on any failure so CI fails.
//

import Foundation

@main
struct Tests {
    static var passed = 0
    static var failed = 0

    static func check(_ condition: Bool, _ message: String, line: Int = #line) {
        if condition {
            passed += 1
            print("ok   - \(message)")
        } else {
            failed += 1
            print("FAIL - \(message) (line \(line))")
        }
    }

    static func main() {
        // CPU sampler ---------------------------------------------------------
        let cpu = CPUSampler()
        check(cpu.sample() == 0, "first CPU sample primes the baseline and returns 0")
        Thread.sleep(forTimeInterval: 0.2)
        let usage = cpu.sample()
        check(usage >= 0 && usage <= 100, "CPU usage stays within 0...100 (got \(usage))")

        // Memory sampler ------------------------------------------------------
        let mem = MemorySampler().sample()
        check(
            mem.totalBytes == ProcessInfo.processInfo.physicalMemory,
            "total memory matches ProcessInfo.physicalMemory"
        )
        check(mem.usedBytes > 0, "used memory is positive")
        check(mem.usedBytes <= mem.totalBytes, "used memory never exceeds total")
        check(mem.percent >= 0 && mem.percent <= 100, "memory percent stays within 0...100 (got \(mem.percent))")

        // MemorySample.percent math ------------------------------------------
        check(MemorySample(usedBytes: 4, totalBytes: 16).percent == 25, "percent computes 25% for 4 / 16")
        check(MemorySample(usedBytes: 10, totalBytes: 0).percent == 0, "percent guards against divide-by-zero")

        print("\n\(passed) passed, \(failed) failed")
        exit(failed == 0 ? 0 : 1)
    }
}
