import AppKit

let destination = CommandLine.arguments[1]
let size = 1024
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor(calibratedRed: 0.13, green: 0.15, blue: 0.09, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 52, y: 52, width: 920, height: 920), xRadius: 205, yRadius: 205).fill()
NSColor(calibratedRed: 0.81, green: 0.86, blue: 0.49, alpha: 1).setFill()
let heights: [CGFloat] = [160, 300, 470, 590, 380, 230, 120]
for (index, height) in heights.enumerated() {
    NSBezierPath(roundedRect: NSRect(x: 222 + CGFloat(index) * 86, y: (1024 - height) / 2,
        width: 48, height: height), xRadius: 24, yRadius: 24).fill()
}
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: destination))
