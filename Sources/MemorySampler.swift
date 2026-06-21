//
//  MemorySampler.swift
//  Latissandra
//
//  Reads memory usage from the kernel via host_statistics64(HOST_VM_INFO64).
//  No network, no entitlements, no private APIs.
//

import Foundation

struct MemorySample {
    let usedBytes: UInt64
    let totalBytes: UInt64

    var percent: Double {
        totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) * 100 : 0
    }
}

/// Samples physical memory usage, approximating Activity Monitor's "Memory Used"
final class MemorySampler {
    private let totalBytes = ProcessInfo.processInfo.physicalMemory

    private let pageSize: UInt64 = {
        var size: vm_size_t = 0
        host_page_size(mach_host_self(), &size)
        return UInt64(size)
    }()

    func sample() -> MemorySample {
        // HOST_VM_INFO64_COUNT isn't importable into Swift ???, so derive it.
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var stats = vm_statistics64_data_t()

        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else {
            return MemorySample(usedBytes: 0, totalBytes: totalBytes)
        }

        // App Memory ≈ anonymous app pages that aren't purgeable.
        let appMemory  = UInt64(stats.internal_page_count) - UInt64(stats.purgeable_count)
        let wired      = UInt64(stats.wire_count)
        let compressed = UInt64(stats.compressor_page_count)

        let usedBytes = (appMemory + wired + compressed) * pageSize
        return MemorySample(usedBytes: min(usedBytes, totalBytes), totalBytes: totalBytes)
    }
}
