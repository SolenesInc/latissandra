//
//  make_icon.swift
//  Latissandra — icon generator
//
//  Renders a 1024×1024 app icon: a white pawprint on a blue→indigo squircle.
//  Reproducible, no external assets. Usage: make_icon <output.png>
//

import AppKit
import Foundation

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
let px = 1024

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("could not create bitmap rep") }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let size = CGFloat(px)
let rect = CGRect(x: 0, y: 0, width: size, height: size)

// Rounded-rect "squircle" clip (approximation of the macOS icon shape).
let radius = size * 0.2237
NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()

// Blue → indigo gradient background.
let top = NSColor(srgbRed: 0.31, green: 0.55, blue: 0.99, alpha: 1)
let bottom = NSColor(srgbRed: 0.42, green: 0.23, blue: 0.88, alpha: 1)
NSGradient(starting: top, ending: bottom)!.draw(in: rect, angle: -90)

// White pawprint, centered, with a soft shadow.
let config = NSImage.SymbolConfiguration(pointSize: size * 0.46, weight: .semibold)
if let base = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: nil),
   let sym = base.withSymbolConfiguration(config) {
    let s = sym.size

    // Tint the template symbol white.
    let white = NSImage(size: s)
    white.lockFocus()
    sym.draw(at: .zero, from: CGRect(origin: .zero, size: s), operation: .sourceOver, fraction: 1)
    NSColor.white.set()
    CGRect(origin: .zero, size: s).fill(using: .sourceAtop)
    white.unlockFocus()

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    shadow.shadowBlurRadius = size * 0.02
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.012)
    shadow.set()

    let drawRect = CGRect(x: (size - s.width) / 2, y: (size - s.height) / 2, width: s.width, height: s.height)
    white.draw(in: drawRect, from: CGRect(origin: .zero, size: s), operation: .sourceOver, fraction: 1)
}

NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("PNG encode failed") }
try! data.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
