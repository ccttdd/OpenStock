import AppKit
import CoreGraphics

let size = 1024
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                     space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

func hex(_ h: UInt32, _ a: CGFloat = 1) -> CGColor {
    let r = CGFloat((h >> 16) & 0xff) / 255
    let g = CGFloat((h >> 8) & 0xff) / 255
    let b = CGFloat(h & 0xff) / 255
    return CGColor(red: r, green: g, blue: b, alpha: a)
}

// Transparent full canvas
ctx.clear(CGRect(x: 0, y: 0, width: size, height: size))

// Rounded-square background (macOS "squircle"-ish), dark navy like OpenStock's UI
let inset: CGFloat = 32
let rect = CGRect(x: inset, y: inset, width: CGFloat(size) - inset * 2, height: CGFloat(size) - inset * 2)
let radius: CGFloat = 224
let bgPath = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

// subtle vertical gradient background
ctx.saveGState()
ctx.addPath(bgPath)
ctx.clip()
let colors = [hex(0x0B1220), hex(0x060A10)] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: CGFloat(size)), end: CGPoint(x: 0, y: 0), options: [])
ctx.restoreGState()

// Thin border for definition
ctx.setStrokeColor(hex(0x1E2A3A))
ctx.setLineWidth(4)
ctx.addPath(bgPath)
ctx.strokePath()

// Candlestick + trend line glyph, teal accent matching brand (#2DD4BF)
let teal = hex(0x2DD4BF)
let tealDim = hex(0x2DD4BF, 0.35)

// Bar chart (three candlesticks) rising
let barWidth: CGFloat = 64
let barSpacing: CGFloat = 96
let baseX: CGFloat = 300
let baseY: CGFloat = 300
let heights: [CGFloat] = [200, 340, 480]
ctx.setFillColor(tealDim)
for (i, h) in heights.enumerated() {
    let x = baseX + CGFloat(i) * barSpacing
    let barRect = CGRect(x: x, y: baseY, width: barWidth, height: h)
    let path = CGPath(roundedRect: barRect, cornerWidth: 16, cornerHeight: 16, transform: nil)
    ctx.addPath(path)
    ctx.fillPath()
}

// Rising trend line across the bars with a dot at the peak
ctx.setStrokeColor(teal)
ctx.setLineWidth(28)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)
let p0 = CGPoint(x: baseX - 20, y: baseY + heights[0] * 0.55)
let p1 = CGPoint(x: baseX + barSpacing + barWidth / 2, y: baseY + heights[1] * 0.85)
let p2 = CGPoint(x: baseX + barSpacing * 2 + barWidth + 40, y: baseY + heights[2] + 40)
let linePath = CGMutablePath()
linePath.move(to: p0)
linePath.addLine(to: p1)
linePath.addLine(to: p2)
ctx.addPath(linePath)
ctx.strokePath()

// Peak dot with glow
ctx.setShadow(offset: .zero, blur: 40, color: hex(0x2DD4BF, 0.9))
ctx.setFillColor(teal)
ctx.addEllipse(in: CGRect(x: p2.x - 34, y: p2.y - 34, width: 68, height: 68))
ctx.fillPath()
ctx.setShadow(offset: .zero, blur: 0, color: nil)

// small upward arrowhead at the very tip
ctx.setFillColor(teal)
let arrow = CGMutablePath()
let tip = CGPoint(x: p2.x + 46, y: p2.y + 70)
arrow.move(to: tip)
arrow.addLine(to: CGPoint(x: tip.x - 54, y: tip.y - 6))
arrow.addLine(to: CGPoint(x: tip.x - 6, y: tip.y - 54))
arrow.closeSubpath()
ctx.addPath(arrow)
ctx.fillPath()

let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
let data = rep.representation(using: .png, properties: [:])!
let outPath = CommandLine.arguments[1]
try! data.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
