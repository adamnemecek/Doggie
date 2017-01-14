//: Playground - noun: a place where people can play

import Cocoa
import Doggie

public func createImage(data rawData: UnsafeRawPointer, size: CGSize) -> CGImage? {
    
    let imageWidth = Int(size.width)
    let imageHeight = Int(size.height)
    
    let bitsPerComponent: Int = 8
    let bytesPerPixel: Int = 4
    let bitsPerPixel: Int = bytesPerPixel * bitsPerComponent
    
    let bytesPerRow = bytesPerPixel * imageWidth
    
    let providerRef = CGDataProvider(data: Data(bytes: rawData.assumingMemoryBound(to: UInt8.self), count: bytesPerRow * imageHeight) as CFData)
    
    let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.last.rawValue)
    
    return CGImage(width: imageWidth, height: imageHeight, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: CGColorSpace(name: CGColorSpace.linearSRGB) ?? CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo, provider: providerRef!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
}

extension NSImage {
    
    public convenience init(cgImage image: CGImage) {
        self.init(cgImage: image, size: NSZeroSize)
    }
}

let lab = CIELabColorSpace(white: Point(x: 0.34567, y: 0.35850))
let luv = CIELuvColorSpace(white: Point(x: 0.34567, y: 0.35850))

let srgb = CalibratedRGBColorSpace(white: XYZColorModel(luminance: 1, x: 0.3127, y: 0.3290), black: XYZColorModel(luminance: 0, x: 0.3127, y: 0.3290), red: XYZColorModel(luminance: 0.2126, x: 0.6400, y: 0.3300), green: XYZColorModel(luminance: 0.7152, x: 0.3000, y: 0.6000), blue: XYZColorModel(luminance: 0.0722, x: 0.1500, y: 0.0600))

srgb.convert(RGBColorModel(red: 1, green: 0, blue: 0), to: lab)
srgb.convert(RGBColorModel(red: 1, green: 0, blue: 0), to: luv)

let size = 128

var buffer = [UInt32](repeating: 0, count: size * size)

for j in 0..<size {
    for i in 0..<size {
        let index = j * size + i
        let x = 256 * Double(i) / Double(size) - 128
        let y = 256 * Double(j) / Double(size) - 128
        let rgb = lab.convert(LabColorModel(lightness: 50, a: x, b: y), to: srgb)
        if (0...1).contains(rgb.red) && (0...1).contains(rgb.green) && (0...1).contains(rgb.blue) {
            let red = UInt32(rgb.red * Double(UInt8.max))
            let green = UInt32(rgb.green * Double(UInt8.max))
            let blue = UInt32(rgb.blue * Double(UInt8.max))
            buffer[index] = red | green << 8 | blue << 16 | 0xff000000
        } else {
            buffer[index] = 0xff000000
        }
    }
}

if let image = createImage(data: &buffer, size: CGSize(width: size, height: size)) {
    
    NSImage(cgImage: image)
}

for j in 0..<size {
    for i in 0..<size {
        let index = j * size + i
        let x = 256 * Double(i) / Double(size) - 128
        let y = 256 * Double(j) / Double(size) - 128
        let rgb = luv.convert(LuvColorModel(lightness: 50, u: x, v: y), to: srgb)
        if (0...1).contains(rgb.red) && (0...1).contains(rgb.green) && (0...1).contains(rgb.blue) {
            let red = UInt32(rgb.red * Double(UInt8.max))
            let green = UInt32(rgb.green * Double(UInt8.max))
            let blue = UInt32(rgb.blue * Double(UInt8.max))
            buffer[index] = red | green << 8 | blue << 16 | 0xff000000
        } else {
            buffer[index] = 0xff000000
        }
    }
}

if let image = createImage(data: &buffer, size: CGSize(width: size, height: size)) {
    
    NSImage(cgImage: image)
}