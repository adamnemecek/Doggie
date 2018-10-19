//
//  CGImageRep.swift
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

protocol CGImageRepBase {
    
    var width: Int { get }
    
    var height: Int { get }
    
    var resolution: Resolution { get }
    
    var numberOfPages: Int { get }
    
    func page(_ index: Int) -> CGImageRepBase
    
    var cgImage: CGImage? { get }
}

public struct CGImageRep {
    
    private let base: CGImageRepBase
    
    private let cache = Cache()
    
    private init(base: CGImageRepBase) {
        self.base = base
    }
}

extension CGImageRep {
    
    @usableFromInline
    class Cache {
        
        let lck = SDLock()
        
        var image: CGImage?
        var pages: [Int: CGImageRep]
        
        @usableFromInline
        init() {
            self.pages = [:]
        }
    }
}

extension CGImageRep {
    
    public init?(data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil).map(_CGImageSourceImageRepBase.init) else { return nil }
        self.base = source
    }
}

extension CGImageRep {
    
    public var numberOfPages: Int {
        return base.numberOfPages
    }
    
    public func page(_ index: Int) -> CGImageRep {
        return cache.lck.synchronized {
            if cache.pages[index] == nil {
                cache.pages[index] = CGImageRep(base: base.page(index))
            }
            return cache.pages[index]!
        }
    }
    
    public var cgImage: CGImage? {
        return cache.lck.synchronized {
            if cache.image == nil {
                cache.image = base.cgImage
            }
            return cache.image
        }
    }
}

extension CGImageRep {
    
    public var width: Int {
        return base.width
    }
    
    public var height: Int {
        return base.height
    }
    
    public var resolution: Resolution {
        return base.resolution
    }
}

struct _CGImageSourceImageRepBase : CGImageRepBase {
    
    let source: CGImageSource
    let index: Int
    let numberOfPages: Int
    
    init(source: CGImageSource, index: Int, numberOfPages: Int) {
        self.source = source
        self.index = index
        self.numberOfPages = numberOfPages
    }
    
    init(source: CGImageSource) {
        self.source = source
        self.index = 0
        self.numberOfPages = CGImageSourceGetCount(source)
    }
    
    var properties: [CFString : Any] {
        return CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString : Any] ?? [:]
    }
    
    var width: Int {
        let width = properties[kCGImagePropertyPixelWidth] as? NSNumber
        return width?.intValue ?? 0
    }
    
    var height: Int {
        let height = properties[kCGImagePropertyPixelHeight] as? NSNumber
        return height?.intValue ?? 0
    }
    
    var resolution: Resolution {
        
        if let resolutionX = properties[kCGImagePropertyDPIWidth] as? NSNumber, let resolutionY = properties[kCGImagePropertyDPIHeight] as? NSNumber {
            
            return Resolution(horizontal: resolutionX.doubleValue, vertical: resolutionY.doubleValue, unit: .inch)
            
        } else if let properties = self.properties[kCGImagePropertyTIFFDictionary] as? [CFString : Any] {
            
            if let resolutionUnit = (properties[kCGImagePropertyTIFFResolutionUnit] as? NSNumber)?.intValue {
                
                let resolutionX = properties[kCGImagePropertyTIFFXResolution] as? NSNumber
                let resolutionY = properties[kCGImagePropertyTIFFYResolution] as? NSNumber
                
                switch resolutionUnit {
                case 1: return Resolution(horizontal: resolutionX?.doubleValue ?? 0, vertical: resolutionY?.doubleValue ?? 0, unit: .point)
                case 2: return Resolution(horizontal: resolutionX?.doubleValue ?? 0, vertical: resolutionY?.doubleValue ?? 0, unit: .inch)
                case 3: return Resolution(horizontal: resolutionX?.doubleValue ?? 0, vertical: resolutionY?.doubleValue ?? 0, unit: .centimeter)
                default: return Resolution(resolution: 1, unit: .point)
                }
            }
        } else if let properties = self.properties[kCGImagePropertyJFIFDictionary] as? [CFString : Any] {
            
            if let resolutionUnit = (properties[kCGImagePropertyJFIFDensityUnit] as? NSNumber)?.intValue {
                
                let resolutionX = properties[kCGImagePropertyJFIFXDensity] as? NSNumber
                let resolutionY = properties[kCGImagePropertyJFIFYDensity] as? NSNumber
                
                switch resolutionUnit {
                case 1: return Resolution(horizontal: resolutionX?.doubleValue ?? 0, vertical: resolutionY?.doubleValue ?? 0, unit: .point)
                case 2: return Resolution(horizontal: resolutionX?.doubleValue ?? 0, vertical: resolutionY?.doubleValue ?? 0, unit: .inch)
                case 3: return Resolution(horizontal: resolutionX?.doubleValue ?? 0, vertical: resolutionY?.doubleValue ?? 0, unit: .centimeter)
                default: return Resolution(resolution: 1, unit: .point)
                }
            }
        } else if let properties = self.properties[kCGImagePropertyPNGDictionary] as? [CFString : Any] {
            
            let resolutionX = properties[kCGImagePropertyPNGXPixelsPerMeter] as? NSNumber
            let resolutionY = properties[kCGImagePropertyPNGYPixelsPerMeter] as? NSNumber
            
            return Resolution(horizontal: resolutionX?.doubleValue ?? 0, vertical: resolutionY?.doubleValue ?? 0, unit: .meter)
        }
        
        return Resolution(resolution: 1, unit: .point)
    }
    
    func page(_ index: Int) -> CGImageRepBase {
        return _CGImageSourceImageRepBase(source: source, index: index, numberOfPages: 1)
    }
    
    var cgImage: CGImage? {
        return CGImageSourceCreateImageAtIndex(source, index, nil)
    }
}

#endif