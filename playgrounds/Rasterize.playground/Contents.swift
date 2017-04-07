//: Playground - noun: a place where people can play

import Cocoa
import Doggie
import PlaygroundSupport

let srgb = CalibratedRGBColorSpace(white: XYZColorModel(luminance: 1, x: 0.3127, y: 0.3290), black: XYZColorModel(luminance: 0, x: 0.3127, y: 0.3290), red: XYZColorModel(luminance: 0.2126, x: 0.6400, y: 0.3300), green: XYZColorModel(luminance: 0.7152, x: 0.3000, y: 0.6000), blue: XYZColorModel(luminance: 0.0722, x: 0.1500, y: 0.0600))

var sample = Image(width: 100, height: 100, pixel: ARGB32ColorPixel(), colorSpace: srgb)

let shape: Shape = [
    Shape.Component(start: Point(x: 50, y: 10), closed: true, segments: [
        .quad(Point(x: 10, y: 10), Point(x: 10, y: 50)),
        .quad(Point(x: 10, y: 90), Point(x: 50, y: 90)),
        .quad(Point(x: 50, y: 50), Point(x: 90, y: 50)),
        .quad(Point(x: 50, y: 50), Point(x: 50, y: 10))
        ])
]

let s = shape.raster(width: sample.width, height: sample.height)

s.withUnsafeBufferPointer { stencil in
    
    if var stencil = stencil.baseAddress {
        
        sample.withUnsafeMutableBytes {
            
            if var ptr = $0.baseAddress?.assumingMemoryBound(to: ARGB32ColorPixel.self) {
                
                for _ in 0..<sample.width * sample.height {
                    
                    let winding = stencil.pointee
                    
                    if winding != 0 {
                        ptr.pointee = ARGB32ColorPixel(red: 0, green: 0, blue: 0, opacity: 255)
                    }
                    
                    stencil += 1
                    ptr += 1
                }
            }
        }
    }
}

let _colorspace = CGColorSpace(name: CGColorSpace.linearSRGB) ?? CGColorSpaceCreateDeviceRGB()
let _bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue

public func createImage(data rawData: UnsafeRawPointer, size: CGSize) -> CGImage? {
    
    let imageWidth = Int(size.width)
    let imageHeight = Int(size.height)
    
    let bitsPerComponent: Int = 8
    let bytesPerPixel: Int = 4
    let bitsPerPixel: Int = bytesPerPixel * bitsPerComponent
    
    let bytesPerRow = bytesPerPixel * imageWidth
    
    return CGImage.create(rawData, width: imageWidth, height: imageHeight, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: _colorspace, bitmapInfo: _bitmapInfo)
}

extension NSImage {
    
    public convenience init(cgImage image: CGImage) {
        self.init(cgImage: image, size: NSZeroSize)
    }
}

sample.withUnsafeBytes {
    if let image = createImage(data: $0.baseAddress!, size: CGSize(width: sample.width, height: sample.height)) {
        NSImage(cgImage: image)
    }
}