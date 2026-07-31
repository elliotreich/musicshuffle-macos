import AppKit

let output = CommandLine.arguments.dropFirst().first ?? "work/musicshuffle-icon-master.png"
let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let bounds = NSRect(x: 0, y: 0, width: size, height: size)
let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 28, dy: 28), xRadius: 210, yRadius: 210)
let gradient = NSGradient(colors: [
    NSColor(calibratedWhite: 0.96, alpha: 1),
    NSColor(calibratedRed: 0.72, green: 0.73, blue: 0.75, alpha: 1)
])!
gradient.draw(in: path, angle: -35)

NSColor.black.withAlphaComponent(0.12).setStroke()
path.lineWidth = 5
path.stroke()

let wheel = NSBezierPath(ovalIn: NSRect(x: 174, y: 174, width: 676, height: 676))
NSColor(calibratedWhite: 0.98, alpha: 1).setFill()
wheel.fill()
NSColor.black.withAlphaComponent(0.11).setStroke()
wheel.lineWidth = 7
wheel.stroke()

if let symbol = NSImage(systemSymbolName: "shuffle", accessibilityDescription: "MusicShuffle") {
    let configured = symbol.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 285, weight: .medium)) ?? symbol
    configured.isTemplate = true
    NSColor(calibratedRed: 0.22, green: 0.16, blue: 0.48, alpha: 1).set()
    configured.draw(in: NSRect(x: 314, y: 314, width: 396, height: 396), from: .zero, operation: .sourceOver, fraction: 1)
}

NSColor(calibratedRed: 0.2, green: 0.62, blue: 0.32, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 480, y: 875, width: 64, height: 64)).fill()
image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    exit(1)
}
try png.write(to: URL(fileURLWithPath: output))
