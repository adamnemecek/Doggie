//
//  Bezier.swift
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

import Foundation

public protocol BezierElementProtocol {
    
    static prefix func + (_: Self) -> Self
    static prefix func - (_: Self) -> Self
    static func + (_: Self, _: Self) -> Self
    static func - (_: Self, _: Self) -> Self
    static func * (_: Double, _: Self) -> Self
    static func * (_: Self, _: Double) -> Self
    static func / (_: Self, _: Double) -> Self
    static func += (_: inout Self, _: Self)
    static func -= (_: inout Self, _: Self)
    static func *= (_: inout Self, _: Double)
    static func /= (_: inout Self, _: Double)
}

extension Double : BezierElementProtocol {
    
}
extension Point : BezierElementProtocol {
    
}
extension Vector : BezierElementProtocol {
    
}

public struct Bezier<Element : BezierElementProtocol> {
    
    fileprivate var points: [Element]
    
    public init(_ p: Element ... ) {
        self.init(p)
    }
    public init<S : Sequence>(_ s: S) where S.Iterator.Element == Element {
        self.points = Array(s)
        assert(self.points.count > 1, "count of points less than 2.")
    }
}
extension Bezier : ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: Element ... ) {
        self.init(elements)
    }
}

extension Bezier : CustomStringConvertible {
    
    public var description: String {
        return "\(points)"
    }
}

extension Bezier : RandomAccessCollection, MutableCollection {
    
    public typealias Indices = CountableRange<Int>
    
    public typealias Index = Int
    
    public var degree: Int {
        return points.count - 1
    }
    public var count: Int {
        return points.count
    }
    public var startIndex: Int {
        return points.startIndex
    }
    public var endIndex: Int {
        return points.endIndex
    }
    
    public subscript(position: Int) -> Element {
        get {
            return points[position]
        }
        set {
            points[position] = newValue
        }
    }
    
    public subscript(bounds: Range<Int>) -> MutableRandomAccessSlice<Bezier> {
        get {
            _failEarlyRangeCheck(bounds, bounds: startIndex..<endIndex)
            return MutableRandomAccessSlice(base: self, bounds: bounds)
        }
        set {
            self = newValue.base
        }
    }
}

extension Bezier {
    
    public func eval(_ t: Double) -> Element {
        switch points.count {
        case 2:
            let p0 = points[0]
            let p1 = points[1]
            return p0 + t * (p1 - p0)
        case 3:
            let _t = 1 - t
            let a = _t * _t * points[0]
            let b = 2 * _t * t * points[1]
            let c = t * t * points[2]
            return a + b + c
        case 4:
            let t2 = t * t
            let _t = 1 - t
            let _t2 = _t * _t
            let a = _t * _t2 * points[0]
            let b = 3 * _t2 * t * points[1]
            let c = 3 * _t * t2 * points[2]
            let d = t * t2 * points[3]
            return a + b + c + d
        default:
            var result: Element?
            let _n = points.count - 1
            for (idx, k) in CombinationList(UInt(_n)).enumerated() {
                let b = Double(k) * pow(t, Double(idx)) * pow(1 - t, Double(_n - idx))
                if result == nil {
                    result = b * points[idx]
                } else {
                    result! += b * points[idx]
                }
            }
            return result!
        }
    }
    
}

extension Bezier where Element == Double {
    
    public var polynomial: Polynomial {
        var result = PermutationList(UInt(points.count - 1)).map(Double.init) as Array
        for i in result.indices {
            var sum = 0.0
            let fact = Array(FactorialList(UInt(i)))
            for (j, f) in zip(fact, fact.reversed()).map(*).enumerated() {
                if (i + j) & 1 == 0 {
                    sum += points[j] / Double(f)
                } else {
                    sum -= points[j] / Double(f)
                }
            }
            result[i] *= sum
        }
        return Polynomial(result)
    }
    
    public init(_ polynomial: Polynomial) {
        let de = (0..<polynomial.degree).scan(polynomial) { p, _ in p.derivative / Double(p.degree) }
        var points: [Double] = []
        for n in de.indices {
            let s = zip(CombinationList(UInt(n)), de)
            points.append(s.reduce(0) { $0 + Double($1.0) * $1.1[0] })
        }
        self.init(points)
    }
}

extension Bezier {
    
    public func elevated() -> Bezier {
        let p = points
        let n = Double(p.count)
        var result = [p[0]]
        for (k, points) in zip(p, p.dropFirst()).enumerated() {
            let t = Double(k + 1) / n
            result.append(t * points.0 + (1 - t) * points.1)
        }
        result.append(p.last!)
        return Bezier(result)
    }
}

extension Bezier {
    
    private static func split(_ t: Double, _ p: [Element]) -> ([Element], [Element]) {
        let _t = 1 - t
        if p.count == 2 {
            let split = _t * p.first! + t * p.last!
            return ([p.first!, split], [split, p.last!])
        }
        var subpath = [Element]()
        var lastPoint = p.first!
        for current in p.dropFirst() {
            subpath.append(_t * lastPoint + t * current)
            lastPoint = current
        }
        let _split = split(t, subpath)
        return ([p.first!] + _split.0, _split.1 + [p.last!])
    }
    public func split(_ t: Double) -> (Bezier, Bezier) {
        if t.almostZero() {
            return (Bezier(repeatElement(points.first!, count: self.count)), self)
        }
        if t.almostEqual(1) {
            return (self, Bezier(repeatElement(points.last!, count: self.count)))
        }
        let split = Bezier.split(t, points)
        return (Bezier(split.0), Bezier(split.1))
    }
    
    public func split(_ t: [Double]) -> [Bezier] {
        var result: [Bezier] = []
        var remain = self
        var last_t = 0.0
        for _t in t.sorted() {
            let split = remain.split((_t - last_t) / (1 - last_t))
            result.append(split.0)
            remain = split.1
            last_t = _t
        }
        result.append(remain)
        return result
    }
}

extension Bezier {
    
    public func derivative() -> Bezier {
        let p = self.points
        let n = Double(p.count - 1)
        var de = [Element]()
        var lastPoint = p.first!
        for current in p.dropFirst() {
            de.append(n * (current - lastPoint))
            lastPoint = current
        }
        return Bezier(de)
    }
}

extension Bezier where Element == Point {
    
    public func closest(_ point: Point) -> [Double] {
        switch points.count {
        case 2:
            let b0 = points[0]
            let b1 = points[1]
            
            let a = b0 - point
            let b = b1 - b0
            let x: Polynomial = [a.x, b.x]
            let y: Polynomial = [a.y, b.y]
            let dot = x * x + y * y
            return dot.derivative.roots.sorted(by: { dot.eval($0) })
        case 3:
            let b0 = points[0]
            let b1 = points[1]
            let b2 = points[2]
            
            let a = b0 - point
            let b = 2 * (b1 - b0)
            let c = b0 - 2 * b1 + b2
            let x: Polynomial = [a.x, b.x, c.x]
            let y: Polynomial = [a.y, b.y, c.y]
            let dot = x * x + y * y
            return dot.derivative.roots.sorted(by: { dot.eval($0) })
        case 4:
            let b0 = points[0]
            let b1 = points[1]
            let b2 = points[2]
            let b3 = points[3]
            
            let a = b0 - point
            let b = 3 * (b1 - b0)
            let c = 3 * (b2 + b0) - 6 * b1
            let d = b3 + 3 * (b1 - b2) - b0
            let x: Polynomial = [a.x, b.x, c.x, d.x]
            let y: Polynomial = [a.y, b.y, c.y, d.y]
            let dot = x * x + y * y
            let y_roots = y.roots
            let roots = x.roots.filter { x in y_roots.contains { x.almostEqual($0) } }
            return roots.count != 0 ? roots.sorted(by: { dot.eval($0) }) : dot.derivative.roots.sorted(by: { dot.eval($0) })
        default:
            let x = Bezier<Double>(points.map { $0.x }).polynomial - point.x
            let y = Bezier<Double>(points.map { $0.y }).polynomial - point.y
            let dot = x * x + y * y
            return dot.derivative.roots.sorted(by: { dot.eval($0) })
        }
    }
}

extension Bezier where Element == Point {
    
    public var area: Double {
        switch points.count {
        case 2:
            let p0 = points[0]
            let p1 = points[1]
            return 0.5 * (p0.x * p1.y - p0.y * p1.x)
        case 3:
            let p0 = points[0]
            let p1 = points[1]
            let p2 = points[2]
            
            let a = p0.x - 2 * p1.x + p2.x
            let b = 2 * (p1.x - p0.x)
            
            let c = p0.y - 2 * p1.y + p2.y
            let d = 2 * (p1.y - p0.y)
            
            return 0.5 * (p0.x * p2.y - p2.x * p0.y) + (b * c - a * d) / 6
        case 4:
            let p0 = points[0]
            let p1 = points[1]
            let p2 = points[2]
            let p3 = points[3]
            
            let a = p3.x - p0.x + 3 * (p1.x - p2.x)
            let b = 3 * (p2.x + p0.x) - 6 * p1.x
            let c = 3 * (p1.x - p0.x)
            
            let d = p3.y - p0.y + 3 * (p1.y - p2.y)
            let e = 3 * (p2.y + p0.y) - 6 * p1.y
            let f = 3 * (p1.y - p0.y)
            
            return 0.5 * (p0.x * p3.y - p3.x * p0.y) + 0.1 * (b * d - a * e) + 0.25 * (c * d - a * f) + (c * e - b * f) / 6
        default:
            let x = Bezier<Double>(points.map { $0.x }).polynomial
            let y = Bezier<Double>(points.map { $0.y }).polynomial
            let t = x * y.derivative - x.derivative * y
            return 0.5 * t.integral.eval(1)
        }
    }
}

extension Bezier where Element == Point {
    
    public var inflection: [Double] {
        switch points.count {
        case 2, 3: return []
        case 4:
            let p0 = points[0]
            let p1 = points[1]
            let p2 = points[2]
            let p3 = points[3]
            
            let p = (p3 - p0).phase
            let _p1 = (p1 - p0) * SDTransform.Rotate(-p)
            let _p2 = (p2 - p0) * SDTransform.Rotate(-p)
            let _p3 = (p3 - p0) * SDTransform.Rotate(-p)
            let a = _p2.x * _p1.y
            let b = _p3.x * _p1.y
            let c = _p1.x * _p2.y
            let d = _p3.x * _p2.y
            let x = 18 * (2 * b + 3 * (c - a) - d)
            let y = 18 * (3 * (a - c) - b)
            let z = 18 * (c - a)
            if x.almostZero() {
                return y.almostZero() ? [] : [-z / y]
            }
            return degree2roots(y / x, z / x)
        default:
            let x = Bezier<Double>(points.map { $0.x }).polynomial.derivative
            let y = Bezier<Double>(points.map { $0.y }).polynomial.derivative
            return (x * y.derivative - y * x.derivative).roots
        }
    }
}

extension Bezier where Element == Double {
    
    public var stationary: [Double] {
        switch points.count {
        case 2: return []
        case 3:
            let p0 = points[0]
            let p1 = points[1]
            let p2 = points[2]
            
            let d = p0 + p2 - 2 * p1
            if d.almostZero() {
                return []
            }
            return [(p0 - p1) / d]
        case 4:
            let p0 = points[0]
            let p1 = points[1]
            let p2 = points[2]
            let p3 = points[3]
            
            let _a = 3 * (p3 - p0) + 9 * (p1 - p2)
            let _b = 6 * (p2 + p0) - 12 * p1
            let _c = 3 * (p1 - p0)
            if _a.almostZero() {
                if _b.almostZero() {
                    return []
                }
                let t = -_c / _b
                return [t]
            } else {
                let delta = _b * _b - 4 * _a * _c
                let _a2 = 2 * _a
                let _b2 = -_b / _a2
                if delta.sign == .plus {
                    let sqrt_delta = sqrt(delta) / _a2
                    let t1 = _b2 + sqrt_delta
                    let t2 = _b2 - sqrt_delta
                    return [t1, t2]
                } else if delta.almostZero() {
                    return [_b2]
                }
            }
            return []
        default: return polynomial.derivative.roots
        }
    }
}

extension Bezier where Element == Point {
    
    public var boundary: Rect {
        
        let bx = Bezier<Double>(points.map { $0.x })
        let by = Bezier<Double>(points.map { $0.y })
        
        let tx = [0.0, 1.0] + bx.stationary.lazy.map { $0.clamped(to: 0...1) }
        let ty = [0.0, 1.0] + by.stationary.lazy.map { $0.clamped(to: 0...1) }
        
        let _x = tx.map { bx.eval($0) }
        let _y = ty.map { by.eval($0) }
        
        let minX = _x.min()!
        let minY = _y.min()!
        let maxX = _x.max()!
        let maxY = _y.max()!
        
        return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

public prefix func + <Element>(x: Bezier<Element>) -> Bezier<Element> {
    return x
}
public prefix func - <Element>(x: Bezier<Element>) -> Bezier<Element> {
    return Bezier(x.points.map { -$0 })
}
public func + <Element>(lhs: Bezier<Element>, rhs: Bezier<Element>) -> Bezier<Element> {
    var lhs = lhs
    var rhs = rhs
    let degree = max(lhs.degree, rhs.degree)
    while lhs.degree != degree {
        lhs = lhs.elevated()
    }
    while rhs.degree != degree {
        rhs = rhs.elevated()
    }
    return Bezier(zip(lhs.points, rhs.points).map(+))
}
public func - <Element>(lhs: Bezier<Element>, rhs: Bezier<Element>) -> Bezier<Element> {
    var lhs = lhs
    var rhs = rhs
    let degree = max(lhs.degree, rhs.degree)
    while lhs.degree != degree {
        lhs = lhs.elevated()
    }
    while rhs.degree != degree {
        rhs = rhs.elevated()
    }
    return Bezier(zip(lhs.points, rhs.points).map(-))
}
public func * <Element>(lhs: Double, rhs: Bezier<Element>) -> Bezier<Element> {
    return Bezier(rhs.points.map { lhs * $0 })
}
public func * <Element>(lhs: Bezier<Element>, rhs: Double) -> Bezier<Element> {
    return Bezier(lhs.points.map { $0 * rhs })
}
public func / <Element>(lhs: Bezier<Element>, rhs: Double) -> Bezier<Element> {
    return Bezier(lhs.points.map { $0 / rhs })
}
public func += <Element>(lhs: inout Bezier<Element>, rhs: Bezier<Element>) {
    lhs = lhs + rhs
}
public func -= <Element>(lhs: inout Bezier<Element>, rhs: Bezier<Element>) {
    lhs = lhs - rhs
}
public func *= <Element>(lhs: inout Bezier<Element>, rhs: Double) {
    lhs = lhs * rhs
}
public func /= <Element>(lhs: inout Bezier<Element>, rhs: Double) {
    lhs = lhs / rhs
}

public func BezierPoint<Element: BezierElementProtocol>(_ t: Double, _ p0: Element, _ p1: Element) -> Element {
    return p0 + t * (p1 - p0)
}
public func BezierPoint<Element: BezierElementProtocol>(_ t: Double, _ p0: Element, _ p1: Element, _ p2: Element) -> Element {
    let _t = 1 - t
    let a = _t * _t * p0
    let b = 2 * _t * t * p1
    let c = t * t * p2
    return a + b + c
}
public func BezierPoint<Element: BezierElementProtocol>(_ t: Double, _ p0: Element, _ p1: Element, _ p2: Element, _ p3: Element) -> Element {
    let t2 = t * t
    let _t = 1 - t
    let _t2 = _t * _t
    let a = _t * _t2 * p0
    let b = 3 * _t2 * t * p1
    let c = 3 * _t * t2 * p2
    let d = t * t2 * p3
    return a + b + c + d
}
public func BezierPoint<Element: BezierElementProtocol>(_ t: Double, _ p0: Element, _ p1: Element, _ p2: Element, _ p3: Element, _ p4: Element, _ rest: Element ... ) -> Element {
    return BezierPoint(t, [p0, p1, p2, p3, p4] + rest)
}

private func SplitBezier<Element: BezierElementProtocol>(_ t: Double, _ p: [Element]) -> ([Element], [Element]) {
    if t.almostZero() {
        return (Array(repeating: p.first!, count: p.count), p)
    }
    if t.almostEqual(1) {
        return (p, Array(repeating: p.last!, count: p.count))
    }
    let _t = 1 - t
    if p.count == 2 {
        let split = _t * p.first! + t * p.last!
        return ([p.first!, split], [split, p.last!])
    }
    var subpath = [Element]()
    var lastPoint = p.first!
    for current in p.dropFirst() {
        subpath.append(_t * lastPoint + t * current)
        lastPoint = current
    }
    let split = SplitBezier(t, subpath)
    return ([p.first!] + split.0, split.1 + [p.last!])
}
@_transparent
private func SplitBezier<Element: BezierElementProtocol>(_ t: [Double], _ p: [Element]) -> [[Element]] {
    var result: [[Element]] = []
    var remain = p
    var last_t = 0.0
    for _t in t.sorted() {
        let split = SplitBezier((_t - last_t) / (1 - last_t), remain)
        result.append(split.0)
        remain = split.1
        last_t = _t
    }
    result.append(remain)
    return result
}

public func SplitBezier<Element: BezierElementProtocol>(_ t: Double, _ p: Element ... ) -> ([Element], [Element]) {
    return SplitBezier(t, p)
}

public func SplitBezier<Element: BezierElementProtocol>(_ t: [Double], _ p: Element ... ) -> [[Element]] {
    return SplitBezier(t, p)
}

@_transparent
private func BezierPoint<Element: BezierElementProtocol>(_ t: Double, _ p: [Element]) -> Element {
    var result: Element?
    let _n = p.count - 1
    for (idx, k) in CombinationList(UInt(_n)).enumerated() {
        let b = Double(k) * pow(t, Double(idx)) * pow(1 - t, Double(_n - idx))
        if result == nil {
            result = b * p[idx]
        } else {
            result! += b * p[idx]
        }
    }
    return result!
}

public func ClosestBezier(_ point: Point, _ b0: Point, _ b1: Point) -> [Double] {
    let a = b0 - point
    let b = b1 - b0
    let x: Polynomial = [a.x, b.x]
    let y: Polynomial = [a.y, b.y]
    let dot = x * x + y * y
    return dot.derivative.roots.sorted(by: { dot.eval($0) })
}

public func ClosestBezier(_ point: Point, _ b0: Point, _ b1: Point, _ b2: Point) -> [Double] {
    let a = b0 - point
    let b = 2 * (b1 - b0)
    let c = b0 - 2 * b1 + b2
    let x: Polynomial = [a.x, b.x, c.x]
    let y: Polynomial = [a.y, b.y, c.y]
    let dot = x * x + y * y
    return dot.derivative.roots.sorted(by: { dot.eval($0) })
}

public func ClosestBezier(_ point: Point, _ b0: Point, _ b1: Point, _ b2: Point, _ b3: Point) -> [Double] {
    let a = b0 - point
    let b = 3 * (b1 - b0)
    let c = 3 * (b2 + b0) - 6 * b1
    let d = b3 + 3 * (b1 - b2) - b0
    let x: Polynomial = [a.x, b.x, c.x, d.x]
    let y: Polynomial = [a.y, b.y, c.y, d.y]
    let dot = x * x + y * y
    let y_roots = y.roots
    let roots = x.roots.filter { x in y_roots.contains { x.almostEqual($0) } }
    return roots.count != 0 ? roots.sorted(by: { dot.eval($0) }) : dot.derivative.roots.sorted(by: { dot.eval($0) })
}

public func ClosestBezier(_ point: Point, _ b0: Point, _ b1: Point, _ b2: Point, _ b3: Point, _ b4: Point , _ b5: Point ... ) -> [Double] {
    let list = [b0, b1, b2, b3, b4] + b5
    let x = Bezier(list.map { $0.x }).polynomial - point.x
    let y = Bezier(list.map { $0.y }).polynomial - point.y
    let dot = x * x + y * y
    return dot.derivative.roots.sorted(by: { dot.eval($0) })
}

// MARK: Inflection

public func CubicBezierInflection(_ p0: Point, _ p1: Point, _ p2: Point, _ p3: Point) -> [Double] {
    
    let p = (p3 - p0).phase
    let _p1 = (p1 - p0) * SDTransform.Rotate(-p)
    let _p2 = (p2 - p0) * SDTransform.Rotate(-p)
    let _p3 = (p3 - p0) * SDTransform.Rotate(-p)
    let a = _p2.x * _p1.y
    let b = _p3.x * _p1.y
    let c = _p1.x * _p2.y
    let d = _p3.x * _p2.y
    let x = 18 * (2 * b + 3 * (c - a) - d)
    let y = 18 * (3 * (a - c) - b)
    let z = 18 * (c - a)
    if x.almostZero() {
        return y.almostZero() ? [] : [-z / y]
    }
    return degree2roots(y / x, z / x)
}
@_transparent
private func BezierInflection(_ p: [Point]) -> [Double] {
    switch p.count {
    case 0, 1, 2, 3: return []
    case 4: return CubicBezierInflection(p[0], p[1], p[2], p[3])
    default:
        let x = Polynomial(Bezier(p.map { $0.x })).derivative
        let y = Polynomial(Bezier(p.map { $0.y })).derivative
        return (x * y.derivative - y * x.derivative).roots
    }
}
public func BezierInflection(_ p: Point ... ) -> [Double] {
    
    return BezierInflection(p)
}

// MARK: Bezier Length

@_transparent
private func QuadBezierLength(_ t: Double, _ a: Double, _ b: Double, _ c: Double) -> Double {
    
    if a.almostZero() {
        if b.almostZero() {
            return sqrt(c) * t
        }
        let g = pow(b * t + c, 1.5)
        let h = pow(c, 1.5)
        return 2 * (g - h) / (3 * b)
    }
    if b.almostZero() {
        let g = sqrt(a * t * t + c)
        let h = sqrt(a)
        let i = log(h * g + a * t)
        let j = log(h * sqrt(c))
        return 0.5 * (t * g + c * (i - j) / h)
    }
    if a.almostEqual(c) && a.almostEqual(-0.5 * b) {
        let g = t - 1
        if g.almostZero() {
            return 0.5 * sqrt(a)
        }
        let h = sqrt(a * g * g)
        return 0.5 * t * (t - 2) * h / g
    }
    
    let delta = b * b - 4 * a * c
    if delta.almostZero() {
        let g = sqrt(a)
        let h = b > 0 ? sqrt(c) : -sqrt(c)
        let i = g * t + h
        if i.almostZero() {
            return 0.5 * c / g
        }
        let j = 0.5 * t * abs(i) * (i + h) / i
        return t < -b / a ? c / g + j : j
    }
    
    let g = 2 * sqrt(a * (t * (a * t + b) + c))
    let h = 2 * a * t + b
    let i = 0.125 * pow(a, -1.5)
    let j = 2 * sqrt(a * c)
    let k = log(g + h)
    let l = log(j + b)
    return i * (g * h - j * b - delta * (k - l))
}
public func QuadBezierLength(_ t: Double, _ p0: Point, _ p1: Point, _ p2: Point) -> Double {
    
    if t.almostZero() {
        return t
    }
    
    let x = Bezier(p0.x, p1.x, p2.x).polynomial.derivative
    let y = Bezier(p0.y, p1.y, p2.y).polynomial.derivative
    
    let u = x * x + y * y
    
    return QuadBezierLength(t, u[2], u[1], u[0])
}
public func InverseQuadBezierLength(_ length: Double, _ p0: Point, _ p1: Point, _ p2: Point) -> Double {
    
    if length.almostZero() {
        return length
    }
    
    let x = Bezier(p0.x, p1.x, p2.x).polynomial.derivative
    let y = Bezier(p0.y, p1.y, p2.y).polynomial.derivative
    
    let u = x * x + y * y
    
    let a = u[2]
    let b = u[1]
    let c = u[0]
    
    if a.almostZero() {
        return b.almostZero() ? length / sqrt(c) : (pow(1.5 * b * length, 2 / 3) - c) / b
    }
    if a.almostEqual(c) && a.almostEqual(-0.5 * b) && length.almostEqual(0.5 * sqrt(a)) {
        return 1
    }
    
    var t = length / QuadBezierLength(1, a, b, c)
    
    t -= (QuadBezierLength(t, a, b, c) - length) / sqrt((a * t + b) * t + c)
    t -= (QuadBezierLength(t, a, b, c) - length) / sqrt((a * t + b) * t + c)
    t -= (QuadBezierLength(t, a, b, c) - length) / sqrt((a * t + b) * t + c)
    t -= (QuadBezierLength(t, a, b, c) - length) / sqrt((a * t + b) * t + c)
    
    return t
}

// MARK: Fitting

public func QuadBezierFitting(_ p0: Point, _ p2: Point, _ m0: Point, _ m2: Point) -> Point? {
    let a = p2.x - p0.x
    let b = p2.y - p0.y
    let c = m0.x * m2.y - m0.y * m2.x
    if c == 0 {
        return nil
    }
    let d = a * m2.y - b * m2.x
    return p0 + m0 * d / c
}

@_transparent
private func QuadBezierFittingCurvature(_ p0: Point, _ p1: Point, _ p2: Point) -> Bool {
    let u = p2 - p0
    let v = p1 - 0.5 * (p2 + p0)
    return u.magnitude < v.magnitude * 3
}
private func QuadBezierFitting(_ p: [Point], _ limit: Int, _ inflection_check: Bool) -> [[Point]] {
    
    if inflection_check {
        let t = BezierInflection(p).filter { !$0.almostZero() && !$0.almostEqual(1) && 0...1 ~= $0 }
        return Bezier(p).split(t).flatMap { QuadBezierFitting($0.points, limit - 1, false) }
    }
    
    let d = zip(p.dropFirst(), p).map { $0 - $1 }
    
    func split(_ t: Double) -> [[Point]] {
        let (left, right) = Bezier(p).split(t)
        return QuadBezierFitting(left.points, limit - 1, false) + QuadBezierFitting(right.points, limit - 1, false)
    }
    
    let start = p.first!
    let end = p.last!
    
    if limit > 0 && p.dropFirst().dropLast().contains(where: { QuadBezierFittingCurvature(start, $0, end) }) {
        return split(0.5)
    }
    
    let m0 = d.first { !$0.x.almostZero() || !$0.y.almostZero() }
    let m1 = d.last { !$0.x.almostZero() || !$0.y.almostZero() }
    
    if let m0 = m0, let m1 = m1 {
        if let mid = QuadBezierFitting(start, end, m0, m1) {
            if QuadBezierFittingCurvature(start, mid, end) {
                if limit > 0 {
                    return split(0.5)
                } else {
                    return [[start, 2 * (Bezier(p).eval(0.5) - 0.25 * (start + end)), end]]
                }
            }
            return [[start, mid, end]]
        }
    }
    return [[start, end]]
}
public func QuadBezierFitting(_ p: [Point]) -> [[Point]] {
    
    return QuadBezierFitting(p, p.count + 4, true)
}

@_transparent
private func BezierFitting(start: Double, end: Double, _ passing: [(Double, Double)]) -> [Double]? {
    
    let n = passing.count
    
    var matrix: [Double] = []
    matrix.reserveCapacity(n * (n + 1))
    
    let c = CombinationList(UInt(n + 1)).dropFirst().dropLast()
    for (t, p) in passing {
        let s = 1 - t
        let tn = pow(t, Double(n + 1))
        let sn = pow(s, Double(n + 1))
        let st = t / s
        let u = sequence(first: sn * st) { $0 * st }
        let v = zip(c, u).lazy.map { Double($0) * $1 }
        matrix.append(contentsOf: v.concat(CollectionOfOne(p - sn * start - tn * end)))
    }
    
    if MatrixElimination(n, &matrix) {
        let a: LazyMapSequence = matrix.lazy.slice(by: n + 1).map { $0.last! }
        let b = CollectionOfOne(start).concat(a).concat(CollectionOfOne(end))
        return Array(b)
    }
    
    return nil
}

public func BezierFitting(start: Double, end: Double, _ passing: (Double, Double) ...) -> [Double]? {
    
    return BezierFitting(start: start, end: end, passing)
}

public func BezierFitting(start: Point, end: Point, _ passing: (Double, Point) ...) -> [Point]? {
    
    let x = BezierFitting(start: start.x, end: end.x, passing.map { ($0, $1.x) })
    let y = BezierFitting(start: start.y, end: end.y, passing.map { ($0, $1.y) })
    if let x = x, let y = y {
        return zip(x, y).map { Point(x: $0, y: $1) }
    }
    return nil
}

public func BezierFitting(start: Vector, end: Vector, _ passing: (Double, Vector) ...) -> [Vector]? {
    
    let x = BezierFitting(start: start.x, end: end.x, passing.map { ($0, $1.x) })
    let y = BezierFitting(start: start.y, end: end.y, passing.map { ($0, $1.y) })
    let z = BezierFitting(start: start.z, end: end.z, passing.map { ($0, $1.z) })
    if let x = x, let y = y, let z = z {
        return zip(zip(x, y), z).map { Vector(x: $0.0, y: $0.1, z: $1) }
    }
    return nil
}

// MARK: Bezier Offset

public func BezierOffset(_ p0: Point, _ p1: Point, _ a: Double) -> (Point, Point)? {
    if a.almostZero() {
        return (p0, p1)
    }
    let _x = p1.x - p0.x
    let _y = p1.y - p0.y
    if _x.almostZero() && _y.almostZero() {
        return nil
    }
    let _xy = sqrt(_x * _x + _y * _y)
    let s = a * _y / _xy
    let t = -a * _x / _xy
    return (p0 + Point(x: s, y: t), p1 + Point(x: s, y: t))
}

@_transparent
private func BezierOffsetCurvature(_ p0: Point, _ p1: Point, _ p2: Point) -> Bool {
    let u = p2 - p0
    let v = p1 - 0.5 * (p2 + p0)
    return u.magnitude < v.magnitude * 3
}

public func BezierOffset(_ p0: Point, _ p1: Point, _ p2: Point, _ a: Double) -> [[Point]] {
    
    return _BezierOffset(p0, p1, p2, a, 8)
}
public func BezierOffset(_ p: [Point], _ a: Double) -> [[Point]] {
    
    return QuadBezierFitting(p).flatMap { points -> [[Point]] in
        switch points.count {
        case 2: return BezierOffset(points[0], points[1], a).map { [[$0, $1]] } ?? []
        case 3: return _BezierOffset(points[0], points[1], points[2], a, 4)
        default: fatalError()
        }
    }
}
private func _BezierOffset(_ p0: Point, _ p1: Point, _ p2: Point, _ a: Double, _ limit: Int) -> [[Point]] {
    
    if a.almostZero() {
        return [[p0, p1, p2]]
    }
    
    let q0 = p1 - p0
    let q1 = p2 - p1
    
    if (q0.x.almostZero() && q0.y.almostZero()) || (q1.x.almostZero() && q1.y.almostZero()) {
        return BezierOffset(p0, p2, a).map { [[$0, $1]] } ?? []
    }
    let ph0 = q0.phase
    let ph1 = q1.phase
    
    if ph0.almostEqual(ph1) || ph0.almostEqual(ph1 + 2 * Double.pi) || ph0.almostEqual(ph1 - 2 * Double.pi) {
        return BezierOffset(p0, p2, a).map { [[$0, $1]] } ?? []
    }
    if ph0.almostEqual(ph1 + Double.pi) || ph0.almostEqual(ph1 - Double.pi) {
        if let w = QuadBezierStationary(p0.x, p1.x, p2.x) ?? QuadBezierStationary(p0.y, p1.y, p2.y) {
            let g = BezierPoint(w, p0, p1, p2)
            let angle = ph0 - 0.5 * Double.pi
            let bezierCircle = BezierCircle.lazy.map { $0 * SDTransform.Rotate(angle) * a + g }
            let v0 = OptionOneCollection(BezierOffset(p0, g, a).map { [$0, $1] })
            let v1 = OptionOneCollection([bezierCircle[0], bezierCircle[1], bezierCircle[2], bezierCircle[3]])
            let v2 = OptionOneCollection([bezierCircle[3], bezierCircle[4], bezierCircle[5], bezierCircle[6]])
            let v3 = OptionOneCollection(BezierOffset(g, p2, a).map { [$0, $1] })
            return Array([v0, v1, v2, v3].joined())
        }
    }
    
    func split(_ t: Double) -> [[Point]] {
        let (left, right) = SplitBezier(t, p0, p1, p2)
        return _BezierOffset(left[0], left[1], left[2], a, limit - 1) + _BezierOffset(right[0], right[1], right[2], a, limit - 1)
    }
    
    if limit > 0 && BezierOffsetCurvature(p0, p1, p2) {
        return split(0.5)
    }
    
    let s = 1 / q0.magnitude
    let t = 1 / q1.magnitude
    let start = Point(x: p0.x + a * q0.y * s, y: p0.y - a * q0.x * s)
    let end = Point(x: p2.x + a * q1.y * t, y: p2.y - a * q1.x * t)
    
    if let mid = QuadBezierFitting(start, end, q0, q1) {
        if BezierOffsetCurvature(start, mid, end) {
            if limit > 0 {
                return split(0.5)
            } else {
                let m = BezierPoint(0.5, q0, q1)
                let _s = 1 / m.magnitude
                let _mid = BezierPoint(0.5, p0, p1, p2) + Point(x: a * m.y * _s, y: -a * m.x * _s)
                return [[start, 2 * (_mid - 0.25 * (start + end)), end]]
            }
        }
        return [[start, mid, end]]
    }
    
    return BezierOffset(p0, p2, a).map { [[$0, $1]] } ?? []
}

private func BezierOffset(_ p0: Point, _ p1: Point, _ p2: Point, _ p3: Point, _ a: Double, _ limit: Int, _ inflection_check: Bool) -> [[Point]] {
    
    let q0 = p1 - p0
    let q1 = p2 - p1
    let q2 = p3 - p2
    
    let z0 = q0.x.almostZero() && q0.y.almostZero()
    let z1 = q1.x.almostZero() && q1.y.almostZero()
    let z2 = q2.x.almostZero() && q2.y.almostZero()
    
    if (z0 && z1) || (z0 && z2) || (z1 && z2) {
        return BezierOffset(p0, p3, a).map { [[$0, $1]] } ?? []
    }
    
    let ph0 = q0.phase
    let ph1 = q1.phase
    let ph2 = q2.phase
    let zh0 = ph0.almostEqual(ph1) || ph0.almostEqual(ph1 + 2 * Double.pi) || ph0.almostEqual(ph1 - 2 * Double.pi)
    let zh1 = ph1.almostEqual(ph2) || ph1.almostEqual(ph2 + 2 * Double.pi) || ph1.almostEqual(ph2 - 2 * Double.pi)
    let zh2 = ph0.almostEqual(ph1 + Double.pi) || ph0.almostEqual(ph1 - Double.pi)
    let zh3 = ph1.almostEqual(ph2 + Double.pi) || ph1.almostEqual(ph2 - Double.pi)
    
    if zh0 && zh1 {
        return BezierOffset(p0, p3, a).map { [[$0, $1]] } ?? []
    }
    if (zh2 && zh3) || (zh2 && zh1) || (zh3 && zh0) {
        var u = CubicBezierStationary(p0.x, p1.x, p2.x, p3.x).sorted()
        if u.count == 0 {
            u = CubicBezierStationary(p0.y, p1.y, p2.y, p3.y).sorted()
        }
        switch u.count {
        case 1:
            let g = BezierPoint(u[0], p0, p1, p2, p3)
            if a.almostZero() {
                return [[p0, g], [g, p3]]
            }
            let angle = ph0 - 0.5 * Double.pi
            let bezierCircle = BezierCircle.lazy.map { $0 * SDTransform.Rotate(angle) * a + g }
            let v0 = OptionOneCollection(BezierOffset(p0, g, a).map { [$0, $1] })
            let v1 = OptionOneCollection([bezierCircle[0], bezierCircle[1], bezierCircle[2], bezierCircle[3]])
            let v2 = OptionOneCollection([bezierCircle[3], bezierCircle[4], bezierCircle[5], bezierCircle[6]])
            let v3 = OptionOneCollection(BezierOffset(g, p3, a).map { [$0, $1] })
            return Array([v0, v1, v2, v3].joined())
        case 2:
            let g = BezierPoint(u[0], p0, p1, p2, p3)
            let h = BezierPoint(u[1], p0, p1, p2, p3)
            if a.almostZero() {
                return [[p0, g], [g, h], [h, p3]]
            }
            let angle1 = ph0 - 0.5 * Double.pi
            let angle2 = ph1 - 0.5 * Double.pi
            let bezierCircle1 = BezierCircle.lazy.map { $0 * SDTransform.Rotate(angle1) * a + g }
            let bezierCircle2 = BezierCircle.lazy.map { $0 * SDTransform.Rotate(angle2) * a + h }
            let v0 = OptionOneCollection(BezierOffset(p0, g, a).map { [$0, $1] })
            let v1 = OptionOneCollection([bezierCircle1[0], bezierCircle1[1], bezierCircle1[2], bezierCircle1[3]])
            let v2 = OptionOneCollection([bezierCircle1[3], bezierCircle1[4], bezierCircle1[5], bezierCircle1[6]])
            let v3 = OptionOneCollection(BezierOffset(g, h, a).map { [$0, $1] })
            let v4 = OptionOneCollection([bezierCircle2[0], bezierCircle2[1], bezierCircle2[2], bezierCircle2[3]])
            let v5 = OptionOneCollection([bezierCircle2[3], bezierCircle2[4], bezierCircle2[5], bezierCircle2[6]])
            let v6 = OptionOneCollection(BezierOffset(h, p3, a).map { [$0, $1] })
            return Array([v0, v1, v2, v3, v4, v5, v6].joined())
        default: break
        }
    }
    
    func split(_ t: Double) -> [[Point]] {
        let (left, right) = SplitBezier(t, p0, p1, p2, p3)
        return BezierOffset(left[0], left[1], left[2], left[3], a, limit - 1, false) + BezierOffset(right[0], right[1], right[2], right[3], a, limit - 1, false)
    }
    
    if inflection_check && limit > 0 {
        let inflection = CubicBezierInflection(p0, p1, p2, p3).filter { !$0.almostZero() && !$0.almostEqual(1) && 0...1 ~= $0 }
        switch inflection.count {
        case 1: return split(inflection[0])
        case 2:
            let paths = SplitBezier(inflection, p0, p1, p2, p3)
            return BezierOffset(paths[0][0], paths[0][1], paths[0][2], paths[0][3], a, limit - 1, false) +
                BezierOffset(paths[1][0], paths[1][1], paths[1][2], paths[1][3], a, limit - 1, false) +
                BezierOffset(paths[2][0], paths[2][1], paths[2][2], paths[2][3], a, limit - 1, false)
        default: break
        }
    }
    if limit > 0 && BezierOffsetCurvature(p0, p1, p2, p3) {
        
        return split(0.5)
    }
    
    let _q0 = z0 ? q1 : q0
    let _q1 = z2 ? q1 : q2
    
    if a.almostZero() {
        if limit > 0, let mid = QuadBezierFitting(p0, p3, _q0, _q1), BezierOffsetCurvature(p0, mid, p3) {
            return split(0.5)
        }
        if let mid = QuadBezierFitting(p0, p3, _q0, _q1) {
            if BezierOffsetCurvature(p0, mid, p3) {
                if limit > 0 {
                    return split(0.5)
                } else {
                    return [[p0, (BezierPoint(0.5, p0, p1, p2, p3) - 0.25 * (p0 + p3)) / 0.5, p3]]
                }
            }
            return [[p0, mid, p3]]
        }
    }
    
    let s = 1 / _q0.magnitude
    let t = 1 / _q1.magnitude
    let start = Point(x: p0.x + a * _q0.y * s, y: p0.y - a * _q0.x * s)
    let end = Point(x: p3.x + a * _q1.y * t, y: p3.y - a * _q1.x * t)
    
    if limit > 0, let mid = QuadBezierFitting(p0, p3, _q0, _q1), BezierOffsetCurvature(p0, mid, p3) {
        return split(0.5)
    }
    if let mid = QuadBezierFitting(start, end, _q0, _q1) {
        if BezierOffsetCurvature(start, mid, end) {
            if limit > 0 {
                return split(0.5)
            } else {
                let m = BezierPoint(0.5, q0, q1 + q1, q2)
                let _s = 1 / m.magnitude
                let _mid = BezierPoint(0.5, p0, p1, p2, p3) + Point(x: a * m.y * _s, y: -a * m.x * _s)
                return [[start, (_mid - 0.25 * (start + end)) / 0.5, end]]
            }
        }
        return [[start, mid, end]]
    }
    
    return BezierOffset(p0, p3, a).map { [[$0, $1]] } ?? []
}

public func BezierVariableOffset(_ p0: Point, _ p1: Point, _ a: [Point]) -> [Point]? {
    let z = p1 - p0
    if z.x.almostZero() && z.y.almostZero() {
        return nil
    }
    let angle = z.phase
    let magnitude = z.magnitude
    return a.map { Point(x: $0.x * magnitude, y: -$0.y) * SDTransform.Rotate(angle) + p0 }
}
public func BezierVariableOffset(_ p0: Point, _ p1: Point, _ p2: Point, _ a: [Point]) -> [[Point]] {
    
    return _BezierVariableOffset(p0, p1, p2, a, 8)
}
private func _BezierVariableOffset(_ p0: Point, _ p1: Point, _ p2: Point, _ a: [Point], _ limit: Int) -> [[Point]] {
    
    let q0 = p1 - p0
    let q1 = p2 - p1
    
    if q0.x.almostZero() && q0.y.almostZero() && q1.x.almostZero() && q1.y.almostZero() {
        return []
    }
    let ph0 = q0.phase
    let ph1 = q1.phase
    
    if ph0.almostEqual(ph1) || ph0.almostEqual(ph1 + 2 * Double.pi) || ph0.almostEqual(ph1 - 2 * Double.pi) {
        return BezierVariableOffset(p0, p2, a).map { [$0] } ?? []
    }
    
    let length = QuadBezierLength(1, p0, p1, p2)
    
    func split_a(_ mid_length: Double) -> ([Point], [Point]) {
        let t = (Bezier(a.map { $0.x }).polynomial - mid_length / length).roots.first { !$0.almostZero() && !$0.almostEqual(1) && 0...1 ~= $0 } ?? mid_length / length
        let (a_left, a_right) = SplitBezier(t, a)
        let a_left_last = a_left.last!
        let a_right_first = a_right.first!
        let a_right_last = a_right.last!
        return (a_left.map { Point(x: $0.x / a_left_last.x, y: $0.y) }, a_right.map { Point(x: ($0.x - a_right_first.x) / (a_right_last.x - a_right_first.x), y: $0.y) })
    }
    
    if ph0.almostEqual(ph1 + Double.pi) || ph0.almostEqual(ph1 - Double.pi) {
        if let w = QuadBezierStationary(p0.x, p1.x, p2.x) ?? QuadBezierStationary(p0.y, p1.y, p2.y) {
            let mid_length = QuadBezierLength(w, p0, p1, p2)
            let g = BezierPoint(w, p0, p1, p2)
            let (a_left, a_right) = split_a(mid_length)
            let a_left_last = a_left.last!
            let angle = ph0 - 0.5 * Double.pi
            let bezierCircle = BezierCircle.lazy.map { $0 * SDTransform.Rotate(angle) * a_left_last.y + g }
            let v0 = OptionOneCollection(BezierVariableOffset(p0, g, a_left))
            let v1 = OptionOneCollection([bezierCircle[0], bezierCircle[1], bezierCircle[2], bezierCircle[3]])
            let v2 = OptionOneCollection([bezierCircle[3], bezierCircle[4], bezierCircle[5], bezierCircle[6]])
            let v3 = OptionOneCollection(BezierVariableOffset(g, p2, a_right))
            return Array([v0, v1, v2, v3].joined())
        }
    }
    
    let half_length = QuadBezierLength(0.5, p0, p1, p2)
    
    func split_half() -> [[Point]] {
        let (p_left, p_right) = SplitBezier(0.5, p0, p1, p2)
        let (a_left, a_right) = split_a(half_length)
        return _BezierVariableOffset(p_left[0], p_left[1], p_left[2], a_left, limit - 1) + _BezierVariableOffset(p_right[0], p_right[1], p_right[2], a_right, limit - 1)
    }
    
    if limit > 0 && BezierOffsetCurvature(p0, p1, p2) {
        return split_half()
    }
    
    let s = 1 / q0.magnitude
    let t = 1 / q1.magnitude
    let a_first = a.first!
    let a_last = a.last!
    let start = Point(x: p0.x + a_first.y * q0.y * s, y: p0.y - a_first.y * q0.x * s)
    let end = Point(x: p2.x + a_last.y * q1.y * t, y: p2.y - a_last.y * q1.x * t)
    
    let za_first = Point(x: a_first.x * length, y: -a_first.y)
    let za_last = Point(x: a_last.x * length, y: -a_last.y)
    let z0 = a.dropFirst().lazy.map { Point(x: $0.x * length, y: -$0.y) - za_first }.first { !$0.x.almostZero() || !$0.y.almostZero() }!
    let z1 = a.dropLast().lazy.map { za_last - Point(x: $0.x * length, y: -$0.y) }.last { !$0.x.almostZero() || !$0.y.almostZero() }!
    
    if let mid = QuadBezierFitting(start, end, q0 * SDTransform.Rotate(z0.phase), q1 * SDTransform.Rotate(z1.phase)) {
        if BezierOffsetCurvature(start, mid, end) {
            if limit > 0 {
                return split_half()
            } else {
                let t = a.count == 2 ? half_length / length : (Bezier(a.map { $0.x }).polynomial - half_length / length).roots.first { !$0.almostZero() && !$0.almostEqual(1) && 0...1 ~= $0 } ?? half_length / length
                let g = BezierPoint(t, a)
                let m = BezierPoint(0.5, q0, q1)
                let _s = 1 / m.magnitude
                let _mid = BezierPoint(0.5, p0, p1, p2) + Point(x: g.y * m.y * _s, y: -g.y * m.x * _s)
                return [[start, 2 * (_mid - 0.25 * (start + end)), end]]
            }
        }
        return [[start, mid, end]]
    }
    
    return BezierVariableOffset(p0, p2, a).map { [$0] } ?? []
}

// MARK: Mesh Warping

public func CoonsPatch(_ m00: Point, _ m01: Point, _ m02: Point, _ m03: Point,
                       _ m10: Point, _ m13: Point, _ m20: Point, _ m23: Point,
                       _ m30: Point, _ m31: Point, _ m32: Point, _ m33: Point,
                       _ p: Point ... ) -> [[Point]] {
    
    let u = Polynomial(Bezier(p.map { $0.x }))
    let v = Polynomial(Bezier(p.map { $0.y }))
    let u2 = u * u
    let v2 = v * v
    let u3 = u2 * u
    let v3 = v2 * v
    
    let _u = 1 - u
    let _v = 1 - v
    let _u2 = _u * _u
    let _v2 = _v * _v
    let _u3 = _u2 * _u
    let _v3 = _v2 * _v
    
    let bx = (m00.x * _u + m03.x * u) * _v + (m30.x * _u + m33.x * u) * v
    let by = (m00.y * _u + m03.y * u) * _v + (m30.y * _u + m33.y * u) * v
    
    let c0x = _u3 * m00.x + 3 * _u2 * u * m01.x + 3 * _u * u2 * m02.x + u3 * m03.x
    let c0y = _u3 * m00.y + 3 * _u2 * u * m01.y + 3 * _u * u2 * m02.y + u3 * m03.y
    let c1x = _u3 * m30.x + 3 * _u2 * u * m31.x + 3 * _u * u2 * m32.x + u3 * m33.x
    let c1y = _u3 * m30.y + 3 * _u2 * u * m31.y + 3 * _u * u2 * m32.y + u3 * m33.y
    let c2x = _v3 * m00.x + 3 * _v2 * v * m10.x + 3 * _v * v2 * m20.x + v3 * m30.x
    let c2y = _v3 * m00.y + 3 * _v2 * v * m10.y + 3 * _v * v2 * m20.y + v3 * m30.y
    let c3x = _v3 * m03.x + 3 * _v2 * v * m13.x + 3 * _v * v2 * m23.x + v3 * m33.x
    let c3y = _v3 * m03.y + 3 * _v2 * v * m13.y + 3 * _v * v2 * m23.y + v3 * m33.y
    
    let d0x = _v * c0x + v * c1x
    let d0y = _v * c0y + v * c1y
    let d1x = _u * c2x + u * c3x
    let d1y = _u * c2y + u * c3y
    
    var x = (d0x + d1x - bx).bezier
    var y = (d0y + d1y - by).bezier
    
    let degree = max(x.degree, y.degree)
    
    while x.degree != degree {
        x = x.elevated()
    }
    while y.degree != degree {
        y = y.elevated()
    }
    
    let points = zip(x, y).map { Point(x: $0, y: $1) }
    
    switch degree {
    case 1, 2, 3: return [points]
    default: return QuadBezierFitting(points)
    }
}

// MARK: Stationary Points

public func QuadBezierStationary(_ p0: Double, _ p1: Double, _ p2: Double) -> Double? {
    let d = p0 + p2 - 2 * p1
    if d.almostZero() {
        return nil
    }
    return (p0 - p1) / d
}

///
/// :param: a value of 'a' in matrix if parallel to x-axis or value of 'd' in matrix if parallel to y-axis.
/// :param: b value of 'b' in matrix if parallel to x-axis or value of 'e' in matrix if parallel to y-axis.
///
/// Transformation Matrix:
///
///     ⎛ a b c ⎞ ⎛ B_x(t) ⎞
///     ⎜ d e f ⎟ ⎜ B_y(t) ⎟
///     ⎝ 0 0 1 ⎠ ⎝   1    ⎠
///
public func QuadBezierStationary(_ p0: Point, _ p1: Point, _ p2: Point, _ a: Double, _ b: Double) -> Double? {
    let d = a * (p0.x + p2.x - 2 * p1.x) + b * (p0.y + p2.y - 2 * p1.y)
    if d.almostZero() {
        return nil
    }
    return (a * (p0.x - p1.x) + b * (p0.y - p1.y)) / d
}

public func CubicBezierStationary(_ p0: Double, _ p1: Double, _ p2: Double, _ p3: Double) -> [Double] {
    let _a = 3 * (p3 - p0) + 9 * (p1 - p2)
    let _b = 6 * (p2 + p0) - 12 * p1
    let _c = 3 * (p1 - p0)
    if _a.almostZero() {
        if _b.almostZero() {
            return []
        }
        let t = -_c / _b
        return [t]
    } else {
        let delta = _b * _b - 4 * _a * _c
        let _a2 = 2 * _a
        let _b2 = -_b / _a2
        if delta.sign == .plus {
            let sqrt_delta = sqrt(delta) / _a2
            let t1 = _b2 + sqrt_delta
            let t2 = _b2 - sqrt_delta
            return [t1, t2]
        } else if delta.almostZero() {
            return [_b2]
        }
    }
    return []
}

///
/// :param: a value of 'a' in matrix if parallel to x-axis or value of 'd' in matrix if parallel to y-axis.
/// :param: b value of 'b' in matrix if parallel to x-axis or value of 'e' in matrix if parallel to y-axis.
///
/// Transformation Matrix:
///
///     ⎛ a b c ⎞ ⎛ B_x(t) ⎞
///     ⎜ d e f ⎟ ⎜ B_y(t) ⎟
///     ⎝ 0 0 1 ⎠ ⎝   1    ⎠
///
public func CubicBezierStationary(_ p0: Point, _ p1: Point, _ p2: Point, _ p3: Point, _ a: Double, _ b: Double) -> [Double] {
    let _ax = 3 * (p3.x - p0.x) + 9 * (p1.x - p2.x)
    let _bx = 6 * (p2.x + p0.x) - 12 * p1.x
    let _cx = 3 * (p1.x - p0.x)
    let _ay = 3 * (p3.y - p0.y) + 9 * (p1.y - p2.y)
    let _by = 6 * (p2.y + p0.y) - 12 * p1.y
    let _cy = 3 * (p1.y - p0.y)
    let _a = a * _ax + b * _ay
    let _b = a * _bx + b * _by
    let _c = a * _cx + b * _cy
    if _a.almostZero() {
        if _b.almostZero() {
            return []
        }
        let t = -_c / _b
        return [t]
    } else {
        let delta = _b * _b - 4 * _a * _c
        let _a2 = 2 * _a
        let _b2 = -_b / _a2
        if delta.sign == .plus {
            let sqrt_delta = sqrt(delta) / _a2
            let t1 = _b2 + sqrt_delta
            let t2 = _b2 - sqrt_delta
            return [t1, t2]
        } else if delta.almostZero() {
            return [_b2]
        }
    }
    return []
}

// MARK: Boundary

public func QuadBezierBound(_ p0: Point, _ p1: Point, _ p2: Point) -> Rect {
    
    let tx = [0.0, QuadBezierStationary(p0.x, p1.x, p2.x).map { $0.clamped(to: 0...1) } ?? 0.0, 1.0]
    let ty = [0.0, QuadBezierStationary(p0.y, p1.y, p2.y).map { $0.clamped(to: 0...1) } ?? 0.0, 1.0]
    
    let _x = tx.map { BezierPoint($0, p0.x, p1.x, p2.x) }
    let _y = ty.map { BezierPoint($0, p0.y, p1.y, p2.y) }
    
    let minX = _x.min()!
    let minY = _y.min()!
    let maxX = _x.max()!
    let maxY = _y.max()!
    
    return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
}

///
/// Transformation Matrix:
///
///     ⎛ a b c ⎞ ⎛ B_x(t) ⎞
///     ⎜ d e f ⎟ ⎜ B_y(t) ⎟
///     ⎝ 0 0 1 ⎠ ⎝   1    ⎠
///
public func QuadBezierBound<T: SDTransformProtocol>(_ p0: Point, _ p1: Point, _ p2: Point, _ matrix: T) -> Rect {
    
    let tx = [0.0, QuadBezierStationary(p0, p1, p2, matrix.a, matrix.b).map { $0.clamped(to: 0...1) } ?? 0.0, 1.0]
    let ty = [0.0, QuadBezierStationary(p0, p1, p2, matrix.d, matrix.e).map { $0.clamped(to: 0...1) } ?? 0.0, 1.0]
    
    let _x = tx.map { t -> Double in
        let _p = BezierPoint(t, p0, p1, p2)
        return matrix.a * _p.x + matrix.b * _p.y
    }
    let _y = ty.map { t -> Double in
        let _p = BezierPoint(t, p0, p1, p2)
        return matrix.d * _p.x + matrix.e * _p.y
    }
    
    let minX = _x.min()!
    let minY = _y.min()!
    let maxX = _x.max()!
    let maxY = _y.max()!
    
    return Rect(x: minX + matrix.c, y: minY + matrix.f, width: maxX - minX, height: maxY - minY)
}

public func CubicBezierBound(_ p0: Point, _ p1: Point, _ p2: Point, _ p3: Point) -> Rect {
    
    let tx = [0.0, 1.0] + CubicBezierStationary(p0.x, p1.x, p2.x, p3.x).lazy.map { $0.clamped(to: 0...1) }
    let ty = [0.0, 1.0] + CubicBezierStationary(p0.y, p1.y, p2.y, p3.y).lazy.map { $0.clamped(to: 0...1) }
    
    let _x = tx.map { BezierPoint($0, p0.x, p1.x, p2.x, p3.x) }
    let _y = ty.map { BezierPoint($0, p0.y, p1.y, p2.y, p3.y) }
    
    let minX = _x.min()!
    let minY = _y.min()!
    let maxX = _x.max()!
    let maxY = _y.max()!
    
    return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
}

///
/// Transformation Matrix:
///
///     ⎛ a b c ⎞ ⎛ B_x(t) ⎞
///     ⎜ d e f ⎟ ⎜ B_y(t) ⎟
///     ⎝ 0 0 1 ⎠ ⎝   1    ⎠
///
public func CubicBezierBound<T: SDTransformProtocol>(_ p0: Point, _ p1: Point, _ p2: Point, _ p3: Point, _ matrix: T) -> Rect {
    
    let tx = [0.0, 1.0] + CubicBezierStationary(p0, p1, p2, p3, matrix.a, matrix.b).lazy.map { $0.clamped(to: 0...1) }
    let ty = [0.0, 1.0] + CubicBezierStationary(p0, p1, p2, p3, matrix.d, matrix.e).lazy.map { $0.clamped(to: 0...1) }
    
    let _x = tx.map { t -> Double in
        let _p = BezierPoint(t, p0, p1, p2, p3)
        return matrix.a * _p.x + matrix.b * _p.y
    }
    let _y = ty.map { t -> Double in
        let _p = BezierPoint(t, p0, p1, p2, p3)
        return matrix.d * _p.x + matrix.e * _p.y
    }
    
    let minX = _x.min()!
    let minY = _y.min()!
    let maxX = _x.max()!
    let maxY = _y.max()!
    
    return Rect(x: minX + matrix.c, y: minY + matrix.f, width: maxX - minX, height: maxY - minY)
}

var BezierCircle: [Point] {
    
    //
    // root of 18225 x^12 + 466560 x^11 - 28977264 x^10 + 63288000 x^9 + 96817248 x^8
    //         - 515232000 x^7 + 883891456 x^6 - 921504768 x^5 + 668905728 x^4
    //         - 342814720 x^3 + 117129216 x^2 - 23592960 x + 2097152
    // reference: http://spencermortensen.com/articles/bezier-circle/
    //
    let c = 0.5519150244935105707435627227925666423361803947243089
    
    return [
        Point(x: 1, y: 0),
        Point(x: 1, y: c),
        Point(x: c, y: 1),
        Point(x: 0, y: 1),
        Point(x: -c, y: 1),
        Point(x: -1, y: c),
        Point(x: -1, y: 0),
        Point(x: -1, y: -c),
        Point(x: -c, y: -1),
        Point(x: 0, y: -1),
        Point(x: c, y: -1),
        Point(x: 1, y: -c),
        Point(x: 1, y: 0)
    ]
}
public func BezierArc(_ angle: Double) -> [Point] {
    
    //
    // root of 18225 x^12 + 466560 x^11 - 28977264 x^10 + 63288000 x^9 + 96817248 x^8
    //         - 515232000 x^7 + 883891456 x^6 - 921504768 x^5 + 668905728 x^4
    //         - 342814720 x^3 + 117129216 x^2 - 23592960 x + 2097152
    // reference: http://spencermortensen.com/articles/bezier-circle/
    //
    let c = 0.5519150244935105707435627227925666423361803947243089
    
    var counter = 0
    var _angle = abs(angle)
    var result = [Point(x: 1, y: 0)]
    
    while _angle > 0 && !_angle.almostZero() {
        switch counter & 3 {
        case 0:
            result.append(Point(x: 1, y: c))
            result.append(Point(x: c, y: 1))
            result.append(Point(x: 0, y: 1))
        case 1:
            result.append(Point(x: -c, y: 1))
            result.append(Point(x: -1, y: c))
            result.append(Point(x: -1, y: 0))
        case 2:
            result.append(Point(x: -1, y: -c))
            result.append(Point(x: -c, y: -1))
            result.append(Point(x: 0, y: -1))
        case 3:
            result.append(Point(x: c, y: -1))
            result.append(Point(x: 1, y: -c))
            result.append(Point(x: 1, y: 0))
        default: break
        }
        if _angle < 0.5 * Double.pi {
            let offset = Double(counter & 3) * 0.5 * Double.pi
            let s = _angle + offset
            let _a = result.count - 4
            let _b = result.count - 3
            let _c = result.count - 2
            let _d = result.count - 1
            let end = Point(x: cos(s), y: sin(s))
            let t = ClosestBezier(end, result[_a], result[_b], result[_c], result[_d]).first!
            let split = SplitBezier(t, result[_a], result[_b], result[_c], result[_d]).0
            result[_b] = split[1]
            result[_c] = split[2]
            result[_d] = end
        }
        _angle -= 0.5 * Double.pi
        counter += 1
    }
    return angle.sign == .minus ? result.map { Point(x: $0.x, y: -$0.y) } : result
}

// MARK: Path Intersection

public func CubicBezierSelfIntersect(_ p0: Point, _ p1: Point, _ p2: Point, _ p3: Point) -> (Double, Double)? {
    
    let a = p3.x - p0.x + 3 * (p1.x - p2.x)
    if a.almostZero() {
        return nil
    }
    
    let b = (3 * (p0.x + p2.x) - 6 * p1.x) / a
    let c = (3 * (p1.x - p0.x)) / a
    
    let d = p3.y - p0.y + 3 * (p1.y - p2.y)
    if d.almostZero() {
        return nil
    }
    let e = (3 * (p0.y + p2.y) - 6 * p1.y) / d
    if b == e {
        return nil
    }
    let f = (3 * (p1.y - p0.y)) / d
    let g = (f - c) / (b - e)
    
    let g_2 = g * g
    
    let _b = -3 * g
    let _c = 3 * g_2 + 2 * (g * b + c)
    let _d = -g_2 * g - b * g_2 - c * g
    let roots = Polynomial(_d, _c, _b, 2).roots
    if roots.count == 3 {
        return (roots.min()!, roots.max()!)
    }
    
    return nil
}

public func LinesIntersect(_ p0: Point, _ p1: Point, _ p2: Point, _ p3: Point) -> Point? {
    
    let d = (p0.x - p1.x) * (p2.y - p3.y) - (p0.y - p1.y) * (p2.x - p3.x)
    if d.almostZero() {
        return nil
    }
    let a = (p0.x * p1.y - p0.y * p1.x) / d
    let b = (p2.x * p3.y - p2.y * p3.x) / d
    return Point(x: (p2.x - p3.x) * a - (p0.x - p1.x) * b, y: (p2.y - p3.y) * a - (p0.y - p1.y) * b)
}

public func QuadBezierLineIntersect(_ b0: Point, _ b1: Point, _ b2: Point, _ l0: Point, _ l1: Point) -> [Double]? {
    
    let a = b0 - l0
    let b = 2 * (b1 - b0)
    let c = b0 - 2 * b1 + b2
    
    let u0: Polynomial = [a.x, b.x, c.x]
    let u1 = l0.x - l1.x
    
    let v0: Polynomial = [a.y, b.y, c.y]
    let v1 = l0.y - l1.y
    
    let poly = u1 * v0 - u0 * v1
    return poly.all(where: { $0.almostZero() }) ? nil : poly.roots
}

public func CubicBezierLineIntersect(_ b0: Point, _ b1: Point, _ b2: Point, _ b3: Point, _ l0: Point, _ l1: Point) -> [Double]? {
    
    let a = b0 - l0
    let b = 3 * (b1 - b0)
    let c = 3 * (b2 + b0) - 6 * b1
    let d = b3 - b0 + 3 * (b1 - b2)
    
    let u0: Polynomial = [a.x, b.x, c.x, d.x]
    let u1 = l0.x - l1.x
    
    let v0: Polynomial = [a.y, b.y, c.y, d.y]
    let v1 = l0.y - l1.y
    
    let poly = u1 * v0 - u0 * v1
    return poly.all(where: { $0.almostZero() }) ? nil : poly.roots
}

public func QuadBeziersIntersect(_ b0: Point, _ b1: Point, _ b2: Point, _ b3: Point, _ b4: Point, _ b5: Point) -> [Double]? {
    
    let a = b0 - b3
    let b = 2 * (b1 - b0)
    let c = b0 - 2 * b1 + b2
    
    let u0: Polynomial = [a.x, b.x, c.x]
    let u1 = 2 * (b3.x - b4.x)
    let u2 = 2 * b4.x - b3.x -  b5.x
    
    let v0: Polynomial = [a.y, b.y, c.y]
    let v1 = 2 * (b3.y - b4.y)
    let v2 = 2 * b4.y - b3.y -  b5.y
    
    // Bézout matrix
    let m00 = u2 * v1 - u1 * v2
    let m01 = u2 * v0 - u0 * v2
    let m10 = m01
    let m11 = u1 * v0 - u0 * v1
    
    let det = m00 * m11 - m01 * m10
    return det.all(where: { $0.almostZero() }) ? nil : det.roots
}

public func CubicQuadBezierIntersect(_ c0: Point, _ c1: Point, _ c2: Point, _ c3: Point, _ q0: Point, _ q1: Point, _ q2: Point) -> [Double]? {
    
    let a = c0 - q0
    let b = 3 * (c1 - c0)
    let c = 3 * (c2 + c0) - 6 * c1
    let d = c3 - c0 + 3 * (c1 - c2)
    
    let u0: Polynomial = [a.x, b.x, c.x, d.x]
    let u1 = 2 * (q0.x - q1.x)
    let u2 = 2 * q1.x - q0.x - q2.x
    
    let v0: Polynomial = [a.y, b.y, c.y, d.y]
    let v1 = 2 * (q0.y - q1.y)
    let v2 = 2 * q1.y - q0.y - q2.y
    
    // Bézout matrix
    let m00 = u2 * v1 - u1 * v2
    let m01 = u2 * v0 - u0 * v2
    let m10 = m01
    let m11 = u1 * v0 - u0 * v1
    
    let det = m00 * m11 - m01 * m10
    return det.all(where: { $0.almostZero() }) ? nil : det.roots
}

public func CubicBeziersIntersect(_ c0: Point, _ c1: Point, _ c2: Point, _ c3: Point, _ c4: Point, _ c5: Point, _ c6: Point, _ c7: Point) -> [Double]? {
    
    let a = c0 - c4
    let b = 3 * (c1 - c0)
    let c = 3 * (c2 + c0) - 6 * c1
    let d = c3 - c0 + 3 * (c1 - c2)
    
    let u0: Polynomial = [a.x, b.x, c.x, d.x]
    let u1 = 3 * (c4.x - c5.x)
    let u2 = 6 * c5.x - 3 * (c6.x + c4.x)
    let u3 = c4.x - c7.x + 3 * (c6.x - c5.x)
    
    let v0: Polynomial = [a.y, b.y, c.y, d.y]
    let v1 = 3 * (c4.y - c5.y)
    let v2 = 6 * c5.y - 3 * (c6.y + c4.y)
    let v3 = c4.y - c7.y + 3 * (c6.y - c5.y)
    
    // Bézout matrix
    let m00 = u3 * v2 - u2 * v3
    let m01 = u3 * v1 - u1 * v3
    let m02 = u3 * v0 - u0 * v3
    let m10 = m01
    let m11 = u2 * v1 - u1 * v2 + m02
    let m12 = u2 * v0 - u0 * v2
    let m20 = m02
    let m21 = m12
    let m22 = u1 * v0 - u0 * v1
    
    let _a = m11 * m22 - m12 * m21
    let _b = m12 * m20 - m10 * m22
    let _c = m10 * m21 - m11 * m20
    let det = m00 * _a + m01 * _b + m02 * _c
    return det.all(where: { $0.almostZero() }) ? nil : det.roots
}

// MARK: Area

public func BezierSignedArea(_ p: Point ...) -> Double {
    
    let x = Bezier(p.map { $0.x }).polynomial
    let y = Bezier(p.map { $0.y }).polynomial
    let t = x * y.derivative - x.derivative * y
    return 0.5 * t.integral.eval(1)
}

public func LineSignedArea(_ p0: Point, _ p1: Point) -> Double {
    
    return 0.5 * (p0.x * p1.y - p0.y * p1.x)
}

public func QuadBezierSignedArea(_ p0: Point, _ p1: Point, _ p2: Point) -> Double {
    
    let a = p0.x - 2 * p1.x + p2.x
    let b = 2 * (p1.x - p0.x)
    
    let c = p0.y - 2 * p1.y + p2.y
    let d = 2 * (p1.y - p0.y)
    
    return 0.5 * (p0.x * p2.y - p2.x * p0.y) + (b * c - a * d) / 6
}

public func CubicBezierSignedArea(_ p0: Point, _ p1: Point, _ p2: Point, _ p3: Point) -> Double {
    
    let a = p3.x - p0.x + 3 * (p1.x - p2.x)
    let b = 3 * (p2.x + p0.x) - 6 * p1.x
    let c = 3 * (p1.x - p0.x)
    
    let d = p3.y - p0.y + 3 * (p1.y - p2.y)
    let e = 3 * (p2.y + p0.y) - 6 * p1.y
    let f = 3 * (p1.y - p0.y)
    
    return 0.5 * (p0.x * p3.y - p3.x * p0.y) + 0.1 * (b * d - a * e) + 0.25 * (c * d - a * f) + (c * e - b * f) / 6
}
