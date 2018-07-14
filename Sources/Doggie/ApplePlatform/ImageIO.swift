//
//  ImageIO.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2018 Susan Cheng. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#if canImport(CoreGraphics) && canImport(ImageIO)

@_exported import ImageIO

public struct CGImageAnimationFrame {
    
    public var image: CGImage
    public var delay: Double
    
    public init(image: CGImage, delay: Double) {
        self.image = image
        self.delay = delay
    }
}

extension CGImage {
    
    private static func withImageDestination(_ type: CFString, _ count: Int, callback: (CGImageDestination) -> Void) -> Data? {
        
        let data = NSMutableData()
        
        guard let imageDestination = CGImageDestinationCreateWithData(data, type, count, nil) else { return nil }
        
        callback(imageDestination)
        
        guard CGImageDestinationFinalize(imageDestination) else { return nil }
        
        return data as Data
    }
}

extension CGImage {
    
    public func representation(using storageType: ImageRep.MediaType, properties: [ImageRep.PropertyKey : Any]) -> Data? {
        
        let type: CFString
        var _properties: [CFString: Any] = [:]
        
        switch storageType {
        case .bmp: type = kUTTypeBMP
        case .gif: type = kUTTypeGIF
        case .jpeg: type = kUTTypeJPEG
        case .jpeg2000: type = kUTTypeJPEG2000
        case .png: type = kUTTypePNG
        case .tiff: type = kUTTypeTIFF
        }
        
        if let compressionQuality = properties[.compressionQuality] as? NSNumber {
            _properties[kCGImageDestinationLossyCompressionQuality] = compressionQuality
        }
        
        return CGImage.withImageDestination(type, 1) { CGImageDestinationAddImage($0, self, _properties as CFDictionary) }
    }
    
    public var tiffRepresentation: Data? {
        return self.representation(using: .tiff, properties: [:])
    }
    
    public var pngRepresentation: Data? {
        return self.representation(using: .png, properties: [:])
    }
    
    public func jpegRepresentation(compressionQuality: Double) -> Data? {
        return self.representation(using: .jpeg, properties: [.compressionQuality: compressionQuality])
    }
}

extension CGImage {
    
    public static func animatedGIFRepresentation(loop: Int, frames: [CGImageAnimationFrame]) -> Data? {
        
        return CGImage.withImageDestination(kUTTypeGIF, frames.count) { imageDestination in
            
            CGImageDestinationSetProperties(imageDestination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: loop]] as CFDictionary)
            
            for frame in frames {
                CGImageDestinationAddImage(imageDestination, frame.image, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: frame.delay]] as CFDictionary)
            }
        }
    }
    
    public static func animatedPNGRepresentation(loop: Int, frames: [CGImageAnimationFrame]) -> Data? {
        
        return CGImage.withImageDestination(kUTTypePNG, frames.count) { imageDestination in
            
            CGImageDestinationSetProperties(imageDestination, [kCGImagePropertyPNGDictionary: [kCGImagePropertyAPNGLoopCount: loop]] as CFDictionary)
            
            for frame in frames {
                CGImageDestinationAddImage(imageDestination, frame.image, [kCGImagePropertyPNGDictionary: [kCGImagePropertyAPNGDelayTime: frame.delay]] as CFDictionary)
            }
        }
    }
}

extension CGImage {
    
    public static func animatedGIFRepresentation(loop: Int, delay: Double, frames: [CGImage]) -> Data? {
        return self.animatedGIFRepresentation(loop: loop, frames: frames.map { CGImageAnimationFrame(image: $0, delay: delay) })
    }
    
    public static func animatedPNGRepresentation(loop: Int, delay: Double, frames: [CGImage]) -> Data? {
        return self.animatedPNGRepresentation(loop: loop, frames: frames.map { CGImageAnimationFrame(image: $0, delay: delay) })
    }
}

#endif
