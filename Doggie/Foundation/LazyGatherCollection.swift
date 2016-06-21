//
//  LazyGatherCollection.swift
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

public extension Collection {
    
    func collect<I : Sequence where Index == I.Iterator.Element>(_ indices: I) -> [Iterator.Element] {
        return indices.map { self[$0] }
    }
}

public struct LazyGatherIterator<C: Collection, I: IteratorProtocol where C.Index == I.Element> : IteratorProtocol, Sequence {
    
    private var seq : C
    private var indices : I
    
    public typealias Element = C.Iterator.Element
    
    public mutating func next() -> Element? {
        return indices.next().map { seq[$0] }
    }
}

public struct LazyGatherSequence<C : Collection, I : Sequence where C.Index == I.Iterator.Element> : LazySequenceProtocol {
    
    public typealias Iterator = LazyGatherIterator<C, I.Iterator>
    
    private let _base: C
    private let _indices: I
    
    public func makeIterator() -> Iterator {
        return LazyGatherIterator(seq: _base, indices: _indices.makeIterator())
    }
}

public struct LazyGatherCollection<C : Collection, I : Collection where C.Index == I.Iterator.Element> : LazyCollectionProtocol {
    
    public typealias Iterator = LazyGatherIterator<C, I.Iterator>
    
    private let _base: C
    private let _indices: I
    
    public subscript(idx: I.Index) -> C.Iterator.Element {
        return _base[_indices[idx]]
    }
    
    public var startIndex : I.Index {
        return _indices.startIndex
    }
    public var endIndex : I.Index {
        return _indices.endIndex
    }
    
    public func index(after i: I.Index) -> I.Index {
        return _indices.index(after: i)
    }
    
    public var count : I.IndexDistance {
        return _indices.count
    }
    
    public func makeIterator() -> Iterator {
        return LazyGatherIterator(seq: _base, indices: _indices.makeIterator())
    }
}

public struct LazyGatherBidirectionalCollection<C : Collection, I : BidirectionalCollection where C.Index == I.Iterator.Element> : LazyCollectionProtocol, BidirectionalCollection {
    
    public typealias Iterator = LazyGatherIterator<C, I.Iterator>
    
    private let _base: C
    private let _indices: I
    
    public subscript(idx: I.Index) -> C.Iterator.Element {
        return _base[_indices[idx]]
    }
    
    public var startIndex : I.Index {
        return _indices.startIndex
    }
    public var endIndex : I.Index {
        return _indices.endIndex
    }
    
    public func index(after i: I.Index) -> I.Index {
        return _indices.index(after: i)
    }
    
    public func index(before i: I.Index) -> I.Index {
        return _indices.index(before: i)
    }
    
    public var count : I.IndexDistance {
        return _indices.count
    }
    
    public func makeIterator() -> Iterator {
        return LazyGatherIterator(seq: _base, indices: _indices.makeIterator())
    }
}

public struct LazyGatherRandomAccessCollection<C : Collection, I : RandomAccessCollection where C.Index == I.Iterator.Element> : LazyCollectionProtocol, RandomAccessCollection {
    
    public typealias Iterator = LazyGatherIterator<C, I.Iterator>
    
    private let _base: C
    private let _indices: I
    
    public subscript(idx: I.Index) -> C.Iterator.Element {
        return _base[_indices[idx]]
    }
    
    public var startIndex : I.Index {
        return _indices.startIndex
    }
    public var endIndex : I.Index {
        return _indices.endIndex
    }
    
    public func index(after i: I.Index) -> I.Index {
        return _indices.index(after: i)
    }
    
    public func index(before i: I.Index) -> I.Index {
        return _indices.index(before: i)
    }
    
    public func index(_ i: I.Index, offsetBy n: I.IndexDistance) -> I.Index {
        return _indices.index(i, offsetBy: n)
    }
    
    public func distance(from start: I.Index, to end: I.Index) -> I.IndexDistance {
        return _indices.distance(from: start, to: end)
    }
    
    public var count : I.IndexDistance {
        return _indices.count
    }
    
    public func makeIterator() -> Iterator {
        return LazyGatherIterator(seq: _base, indices: _indices.makeIterator())
    }
}

public extension LazyCollectionProtocol {
    
    func collect<I : Sequence where Elements.Index == I.Iterator.Element>(_ indices: I) -> LazyGatherSequence<Elements, I> {
        return LazyGatherSequence(_base: self.elements, _indices: indices)
    }
    
    func collect<I : Collection where Elements.Index == I.Iterator.Element>(_ indices: I) -> LazyGatherCollection<Elements, I> {
        return LazyGatherCollection(_base: self.elements, _indices: indices)
    }
    
    func collect<I : BidirectionalCollection where Elements.Index == I.Iterator.Element>(_ indices: I) -> LazyGatherBidirectionalCollection<Elements, I> {
        return LazyGatherBidirectionalCollection(_base: self.elements, _indices: indices)
    }
    
    func collect<I : RandomAccessCollection where Elements.Index == I.Iterator.Element>(_ indices: I) -> LazyGatherRandomAccessCollection<Elements, I> {
        return LazyGatherRandomAccessCollection(_base: self.elements, _indices: indices)
    }
}