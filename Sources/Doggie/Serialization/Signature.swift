//
//  Signature.swift
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

protocol SignatureProtocol: RawRepresentable, Hashable, ExpressibleByIntegerLiteral, ExpressibleByStringLiteral, CustomStringConvertible, ByteCodable {
    
    associatedtype Bytes : FixedWidthInteger
    
    var rawValue: Bytes { get set }
    
    init(rawValue: Bytes)
}

extension SignatureProtocol {
    
    @_transparent
    init(integerLiteral value: Bytes.IntegerLiteralType) {
        self.init(rawValue: Bytes(integerLiteral: value))
    }
    
    @_transparent
    init(stringLiteral value: StaticString) {
        precondition(value.utf8CodeUnitCount == Bytes.bitWidth >> 3)
        self.init(rawValue: value.utf8Start.withMemoryRebound(to: Bytes.self, capacity: 1) { Bytes(bigEndian: $0.pointee) })
    }
    
    @_transparent
    var description: String {
        var code = self.rawValue.bigEndian
        return String(bytes: UnsafeRawBufferPointer(start: &code, count: Bytes.bitWidth >> 3), encoding: .ascii) ?? ""
    }
}

extension SignatureProtocol where Bytes : ByteEncodable {
    
    @_transparent
    func write(to stream: ByteOutputStream) {
        self.rawValue.write(to: stream)
    }
}
extension SignatureProtocol where Bytes : ByteDecodable {
    
    @_transparent
    init(from data: inout Data) throws {
        self.init(rawValue: try Bytes(from: &data))
    }
}

struct Signature<Bytes : FixedWidthInteger & ByteCodable> : SignatureProtocol {
    
    var rawValue: Bytes
    
    @_transparent
    init(rawValue: Bytes) {
        self.rawValue = rawValue
    }
}

