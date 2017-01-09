//
//  SDShape.swift
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

public protocol SDShape {
    
    /// Boundary of shape without transform.
    var originalBoundary : Rect { get }
    /// Boundary of transformed shape.
    var boundary : Rect { get }
    /// Transformed points of `originalBoundary`.
    var frame : [Point] { get }
    var baseTransform : SDTransform { get set }
    /// Transformation of shape
    var transform : SDTransform { get set }
    
    var path: SDPath { get }
    
    /// Center of shape.
    var center : Point { get set }
    /// Rotation of shape.
    var rotate: Double { get set }
    /// Scaling of shape.
    var scale: Double { get set }
    
    /// area of shape
    var area: Double { get }
}

extension SDShape {
    
    public var frame : [Point] {
        let _transform = self.transform
        return originalBoundary.points.map { $0 * _transform }
    }
}

extension SDShape {
    
    public var transform : SDTransform {
        get {
            return baseTransform * SDTransform.Scale(scale) as SDTransform * SDTransform.Rotate(rotate)
        }
        set {
            baseTransform = newValue * SDTransform.Rotate(rotate).inverse * SDTransform.Scale(scale).inverse
        }
    }
}

extension SDShape {
    
    public var area: Double {
        return path.area
    }
}