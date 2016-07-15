//
//  Environment.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2016 Susan Cheng. All rights reserved.
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

public let isLittleEndian = TARGET_RT_LITTLE_ENDIAN == 1
public let isBigEndian = TARGET_RT_BIG_ENDIAN == 1

public let Progname = String(cString: getprogname())

public func Environment(name: String) -> String? {
    return String(cString: getenv(name))
}

public func SDTimer(count: Int = 1, block: @noescape () -> Void) -> TimeInterval {
    var time: UInt64 = 0
    for _ in 0..<count {
        autoreleasepool {
            let start = mach_absolute_time()
            block()
            time += mach_absolute_time() - start
        }
    }
    var timebaseInfo = mach_timebase_info()
    mach_timebase_info(&timebaseInfo)
    let frac = Double(timebaseInfo.numer) / Double(timebaseInfo.denom)
    return 1e-9 * Double(time) * frac / Double(count)
}

private let _hash_phi = 0.6180339887498948482045868343656381177203091798057628
private let _hash_seed = Int(bitPattern: UInt(round(_hash_phi * Double(UInt.max))))

public func hash_combine<T: Hashable>(seed: Int, _ value: T) -> Int {
    let a = seed << 6
    let b = seed >> 2
    let c = value.hashValue &+ _hash_seed &+ a &+ b
    return seed ^ c
}
public func hash_combine<S: Sequence where S.Iterator.Element : Hashable>(seed: Int, _ values: S) -> Int {
    return values.reduce(seed, combine: hash_combine)
}
public func hash_combine<T: Hashable>(seed: Int, _ a: T, _ b: T, _ res: T ... ) -> Int {
    return hash_combine(seed, CollectionOfOne(a).concat(with: CollectionOfOne(b)).concat(with: res))
}
