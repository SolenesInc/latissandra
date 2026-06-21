//
//  CPUSampler.swift
//  Latissandra
//
//  Reads overall CPU usage from the kernel via host_statistics(HOST_CPU_LOAD_INFO).
//  No network, no entitlements, no private APIs.
//

import Foundation

/// Samples system-wide CPU usage as a percentage (0–100).
///
/// CPU usage is a rate, not a snapshot: the kernel exposes cumulative "ticks"
/// spent in each state since boot.
/// The first call only primes the baseline and returns 0.
///
final class CPUSampler {
    private var previous: host_cpu_load_info_data_t?

    func sample() -> Double {
        // HOST_CPU_LOAD_INFO_COUNT isn't importable into Swift (sizeof macro), so derive it.
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        var info = host_cpu_load_info_data_t()

        let result = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }

        defer { previous = info }
        guard let prev = previous else { return 0 } // first call: prime baseline only

        // cpu_ticks indices: 0 = user, 1 = system, 2 = idle, 3 = nice.
        let user   = Double(info.cpu_ticks.0) - Double(prev.cpu_ticks.0)
        let system = Double(info.cpu_ticks.1) - Double(prev.cpu_ticks.1)
        let idle   = Double(info.cpu_ticks.2) - Double(prev.cpu_ticks.2)
        let nice   = Double(info.cpu_ticks.3) - Double(prev.cpu_ticks.3)

        let busy = user + system + nice
        let total = busy + idle
        guard total > 0 else { return 0 }

        return max(0, min(100, busy / total * 100))
    }
}
