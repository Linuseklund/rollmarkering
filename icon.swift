import Cocoa
let S: CGFloat = 1024
let img = NSImage(size: NSSize(width: S, height: S))
img.lockFocus()
let r = NSRect(x: 100, y: 100, width: 824, height: 824)
let bg = NSBezierPath(roundedRect: r, xRadius: 185, yRadius: 185)
NSGradient(starting: NSColor(red: 0.95, green: 0.90, blue: 0.80, alpha: 1), ending: NSColor(red: 0.86, green: 0.78, blue: 0.64, alpha: 1))!.draw(in: bg, angle: -90)
// bildruta (filmruta)
NSColor(white: 0.13, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 190, y: 290, width: 644, height: 444), xRadius: 40, yRadius: 40).fill()
for i in 0..<7 { let x = 225 + CGFloat(i) * 90
  NSColor(white: 0.85, alpha: 1).setFill()
  NSBezierPath(roundedRect: NSRect(x: x, y: 690, width: 44, height: 26), xRadius: 6, yRadius: 6).fill()
  NSBezierPath(roundedRect: NSRect(x: x, y: 308, width: 44, height: 26), xRadius: 6, yRadius: 6).fill() }
NSGradient(starting: NSColor(red: 0.40, green: 0.66, blue: 0.72, alpha: 1), ending: NSColor(red: 0.20, green: 0.44, blue: 0.52, alpha: 1))!.draw(in: NSBezierPath(rect: NSRect(x: 220, y: 350, width: 584, height: 324)), angle: -90)
// markeringar: färgade prickar med ring
func dot(_ x: CGFloat, _ y: CGFloat, _ c: NSColor, _ rr: CGFloat) {
  NSColor.white.setFill(); NSBezierPath(ovalIn: NSRect(x: x - rr - 12, y: y - rr - 12, width: (rr + 12) * 2, height: (rr + 12) * 2)).fill()
  c.setFill(); NSBezierPath(ovalIn: NSRect(x: x - rr, y: y - rr, width: rr * 2, height: rr * 2)).fill()
}
dot(380, 490, NSColor(red: 0.82, green: 0.41, blue: 0.24, alpha: 1), 62)
dot(620, 560, NSColor(red: 0.17, green: 0.55, blue: 0.58, alpha: 1), 50)
dot(560, 420, NSColor(red: 0.43, green: 0.36, blue: 0.69, alpha: 1), 40)
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "icon_1024.png"))
