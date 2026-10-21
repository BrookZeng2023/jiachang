#!/usr/bin/env swift
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")

func canvas(size: Int, transparent: Bool = false, draw: (CGFloat) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    if transparent {
        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: size, height: size).fill()
    }
    draw(CGFloat(size))
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func drawMark(size: CGFloat, white: NSColor = .white) {
    let scale = size / 1024
    func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x * scale, y: y * scale) }

    white.setStroke()
    white.setFill()

    let rim = NSBezierPath(roundedRect: NSRect(x: 248 * scale, y: 438 * scale, width: 528 * scale, height: 92 * scale), xRadius: 46 * scale, yRadius: 46 * scale)
    rim.lineWidth = 26 * scale
    rim.stroke()

    let bowl = NSBezierPath()
    bowl.move(to: point(278, 482))
    bowl.curve(to: point(512, 238), controlPoint1: point(300, 342), controlPoint2: point(390, 238))
    bowl.curve(to: point(746, 482), controlPoint1: point(634, 238), controlPoint2: point(724, 342))
    bowl.close()
    bowl.fill()

    let foot = NSBezierPath(roundedRect: NSRect(x: 408 * scale, y: 204 * scale, width: 208 * scale, height: 42 * scale), xRadius: 21 * scale, yRadius: 21 * scale)
    foot.fill()

    for x in [392.0, 512.0, 632.0] {
        let steam = NSBezierPath()
        steam.move(to: point(x, 588))
        steam.curve(to: point(x - 16, 704), controlPoint1: point(x + 54, 634), controlPoint2: point(x - 66, 660))
        steam.curve(to: point(x + 8, 818), controlPoint1: point(x + 44, 744), controlPoint2: point(x - 34, 784))
        steam.lineWidth = 28 * scale
        steam.lineCapStyle = .round
        steam.stroke()
    }
}

let icon = canvas(size: 1024) { size in
    NSGradient(colors: [NSColor(calibratedRed: 0.93, green: 0.35, blue: 0.16, alpha: 1), NSColor(calibratedRed: 0.63, green: 0.12, blue: 0.07, alpha: 1)])!
        .draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: -48)
    NSColor.white.withAlphaComponent(0.08).setFill()
    NSBezierPath(ovalIn: NSRect(x: -90, y: 590, width: 570, height: 570)).fill()
    NSColor(calibratedRed: 1, green: 0.70, blue: 0.29, alpha: 0.17).setFill()
    NSBezierPath(ovalIn: NSRect(x: 590, y: -70, width: 520, height: 520)).fill()
    drawMark(size: size)
}

let launch = canvas(size: 512, transparent: true) { size in
    drawMark(size: size)
}

try FileManager.default.createDirectory(at: root.appendingPathComponent("AppIcon.appiconset"), withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: root.appendingPathComponent("LaunchMark.imageset"), withIntermediateDirectories: true)
try icon.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("AppIcon.appiconset/AppIcon.png"))
try launch.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("LaunchMark.imageset/LaunchMark.png"))
