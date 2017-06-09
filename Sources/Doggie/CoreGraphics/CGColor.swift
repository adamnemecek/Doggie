//
//  CGColor.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2017 Susan Cheng. All rights reserved.
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

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    
    import Foundation
    import CoreGraphics
    
    extension Color {
        
        public var cgColor: CGColor? {
            return colorSpace.cgColorSpace.flatMap { CGColor(colorSpace: $0, components: self.color.components.map { CGFloat($0) } + [CGFloat(opacity)]) }
        }
    }
    
#endif

#if os(iOS) || os(tvOS) || os(watchOS)
    
    import UIKit
    
    extension CGColor : CustomPlaygroundQuickLookable {
        
        public var customPlaygroundQuickLook: PlaygroundQuickLook {
            
            return PlaygroundQuickLook.color(UIColor(cgColor: self))
        }
    }
    
#endif

#if os(macOS)
    
    import AppKit
    
    extension CGColor : CustomPlaygroundQuickLookable {
        
        public var customPlaygroundQuickLook: PlaygroundQuickLook {
            
            return PlaygroundQuickLook.color(NSColor(cgColor: self)!)
        }
    }
    
#endif

