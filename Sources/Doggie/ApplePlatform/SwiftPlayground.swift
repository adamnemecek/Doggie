//
//  SwiftPlayground.swift
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

import Foundation

extension Point : CustomPlaygroundDisplayConvertible {
    
    @_inlineable
    public var playgroundDescription: Any {
        return CGPoint(self)
    }
}

extension Size : CustomPlaygroundDisplayConvertible {
    
    @_inlineable
    public var playgroundDescription: Any {
        return CGSize(self)
    }
}

extension Rect : CustomPlaygroundDisplayConvertible {
    
    @_inlineable
    public var playgroundDescription: Any {
        return CGRect(self)
    }
}

extension Image : CustomPlaygroundDisplayConvertible {
    
    @_inlineable
    public var playgroundDescription: Any {
        
        #if canImport(CoreGraphics)
        
        return cgImage ?? description
        
        #else
        
        return description
        
        #endif
    }
}

extension AnyImage : CustomPlaygroundDisplayConvertible {
    
    @_inlineable
    public var playgroundDescription: Any {
        
        #if canImport(CoreGraphics)
        
        return cgImage ?? "\(self)"
        
        #else
        
        return "\(self)"
        
        #endif
    }
}

extension Color : CustomPlaygroundDisplayConvertible {
    
    @_inlineable
    public var playgroundDescription: Any {
        
        #if canImport(CoreGraphics)
        
        return cgColor ?? "\(self)"
        
        #else
        
        return "\(self)"
        
        #endif
    }
}

extension AnyColor : CustomPlaygroundDisplayConvertible {
    
    @_inlineable
    public var playgroundDescription: Any {
        
        #if canImport(CoreGraphics)
        
        return cgColor ?? "\(self)"
        
        #else
        
        return "\(self)"
        
        #endif
    }
}

#if canImport(AppKit)

import AppKit

extension Shape : CustomPlaygroundDisplayConvertible {
    
    @_inlineable
    public var playgroundDescription: Any {
        return NSBezierPath(self)
    }
}

extension ShapeRegion : CustomPlaygroundDisplayConvertible {
    
    @_inlineable
    public var playgroundDescription: Any {
        return NSBezierPath(self.shape)
    }
}

extension ShapeRegion.Solid : CustomPlaygroundDisplayConvertible {
    
    @_inlineable
    public var playgroundDescription: Any {
        return NSBezierPath(self.shape)
    }
}

#endif

#if canImport(UIKit)

import UIKit

extension Shape : CustomPlaygroundDisplayConvertible {
    
    @_inlineable
    public var playgroundDescription: Any {
        return UIBezierPath(self)
    }
}

extension ShapeRegion : CustomPlaygroundDisplayConvertible {
    
    @_inlineable
    public var playgroundDescription: Any {
        return UIBezierPath(self.shape)
    }
}

extension ShapeRegion.Solid : CustomPlaygroundDisplayConvertible {
    
    @_inlineable
    public var playgroundDescription: Any {
        return UIBezierPath(self.shape)
    }
}

#endif