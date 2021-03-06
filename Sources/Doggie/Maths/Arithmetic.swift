//
//  Arithmetic.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2019 Susan Cheng. All rights reserved.
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

public protocol AdditiveArithmetic : Equatable {

    static var zero: Self { get }

    static func + (lhs: Self, rhs: Self) -> Self

    static func += (lhs: inout Self, rhs: Self)

    static func - (lhs: Self, rhs: Self) -> Self

    static func -= (lhs: inout Self, rhs: Self)

    static prefix func + (x: Self) -> Self

    static prefix func - (x: Self) -> Self
}

extension AdditiveArithmetic where Self: ExpressibleByIntegerLiteral {

    @_transparent
    public static var zero: Self {
        return 0
    }
}

public protocol ScalarProtocol: SignedNumeric, Strideable, ExpressibleByFloatLiteral, Multiplicative, ScalarMultiplicative where Scalar == Self {

    static func * (lhs: Self, rhs: Self) -> Self

    static func *= (lhs: inout Self, rhs: Self)
}

public protocol ScalarMultiplicative : AdditiveArithmetic {

    associatedtype Scalar : ScalarProtocol

    static func * (lhs: Scalar, rhs: Self) -> Self

    static func * (lhs: Self, rhs: Scalar) -> Self

    static func *= (lhs: inout Self, rhs: Scalar)

    static func / (lhs: Self, rhs: Scalar) -> Self

    static func /= (lhs: inout Self, rhs: Scalar)
}

public protocol Multiplicative : Equatable {

    static func * (lhs: Self, rhs: Self) -> Self

    static func *= (lhs: inout Self, rhs: Self)
}

public protocol MapReduceArithmetic {

    associatedtype Element

    func map(_ transform: (Element) -> Element) -> Self

    func reduce(_ nextPartialResult: (Element, Element) -> Element) -> Element?

    func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Element) -> Result) -> Result

    func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Element) -> ()) -> Result
}

extension MapReduceArithmetic {

    @inlinable
    @inline(__always)
    public func reduce(_ nextPartialResult: (Element, Element) -> Element) -> Element? {
        return self.reduce(nil) { partial, current in partial.map { nextPartialResult($0, current) } ?? current }
    }

    @inlinable
    @inline(__always)
    public func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Element) -> Result) -> Result {
        return self.reduce(into: initialResult) { $0 = nextPartialResult($0, $1) }
    }
}

extension MapReduceArithmetic where Element == Point {

    @inlinable
    @inline(__always)
    public static func * (lhs: Self, rhs: SDTransform) -> Self {
        return lhs.map { $0 * rhs }
    }

    @inlinable
    @inline(__always)
    public static func *= (lhs: inout Self, rhs: SDTransform) {
        lhs = lhs * rhs
    }
}

extension MapReduceArithmetic where Element == Vector {

    @inlinable
    @inline(__always)
    public static func * (lhs: Self, rhs: Matrix) -> Self {
        return lhs.map { $0 * rhs }
    }

    @inlinable
    @inline(__always)
    public static func *= (lhs: inout Self, rhs: Matrix) {
        lhs = lhs * rhs
    }
}

extension MapReduceArithmetic where Self : AdditiveArithmetic, Element : AdditiveArithmetic {

    @inlinable
    @inline(__always)
    public static prefix func + (val: Self) -> Self {
        return val
    }

    @inlinable
    @inline(__always)
    public static prefix func - (val: Self) -> Self {
        return val.map { -$0 }
    }

    @inlinable
    @inline(__always)
    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    @inlinable
    @inline(__always)
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }
}

extension MapReduceArithmetic where Self : ScalarMultiplicative, Element : ScalarMultiplicative, Self.Scalar == Element.Scalar {

    @inlinable
    @inline(__always)
    public static func * (lhs: Scalar, rhs: Self) -> Self {
        return rhs.map { lhs * $0 }
    }
    @inlinable
    @inline(__always)
    public static func * (lhs: Self, rhs: Scalar) -> Self {
        return lhs.map { $0 * rhs }
    }
    @inlinable
    @inline(__always)
    public static func / (lhs: Self, rhs: Scalar) -> Self {
        return lhs.map { $0 / rhs }
    }
    @inlinable
    @inline(__always)
    public static func *= (lhs: inout Self, rhs: Scalar) {
        lhs = lhs * rhs
    }
    @inlinable
    @inline(__always)
    public static func /= (lhs: inout Self, rhs: Scalar) {
        lhs = lhs / rhs
    }
}
