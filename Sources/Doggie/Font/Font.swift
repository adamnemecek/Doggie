//
//  Font.swift
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

protocol FontFaceBase {
    
    func shape(glyph: Int) -> [Shape.Component]
    func glyph(unicode: UnicodeScalar) -> Int
    func advanceWidth(glyph: Int) -> Double
    func advanceHeight(glyph: Int) -> Double
    
    var numberOfGlyphs: Int { get }
    
    var coveredCharacterSet: CharacterSet { get }
    
    var ascender: Double { get }
    var descender: Double { get }
    var lineGap: Double { get }
    
    var verticalAscender: Double? { get }
    var verticalDescender: Double? { get }
    var verticalLineGap: Double? { get }
    
    var unitsPerEm: Double { get }
    var boundingRectForFont: Rect { get }
    
    var italicAngle: Double { get }
    var weight: Int? { get }
    var stretch: Int? { get }
    var isFixedPitch: Bool { get }
    var isItalic: Bool { get }
    var isBold: Bool { get }
    var isExpanded: Bool { get }
    var isCondensed: Bool { get }
    var underlinePosition: Double { get }
    var underlineThickness: Double { get }
    
    var fontName: String? { get }
    var displayName: String? { get }
    var uniqueName: String? { get }
    var familyName: String? { get }
    var faceName: String? { get }
    
    var familyClass: Font.FamilyClass? { get }
    
    var designer: String? { get }
    
    var version: String? { get }
    
    var trademark: String? { get }
    var manufacturer: String? { get }
    var license: String? { get }
    var copyright: String? { get }
}

public struct Font {
    
    private let details: Details
    private let base: FontFaceBase
    private let cache: Cache
    
    public var pointSize: Double = 0
    
    init?(_ base: FontFaceBase) {
        guard let details = Details(base) else { return nil }
        self.details = details
        self.base = base
        self.cache = Cache()
    }
    
    public init(font: Font, size: Double) {
        self.details = font.details
        self.base = font.base
        self.cache = font.cache
        self.pointSize = size
    }
}

extension Font {
    
    private class Cache {
        
        var coveredCharacterSet: CharacterSet?
        var glyphs: [Int: [Shape.Component]] = [:]
    }
}

extension Font {
    
    private struct Details {
        
        let fontName: String
        let displayName: String?
        let uniqueName: String?
        let familyName: String?
        let faceName: String?
        let familyClass: FamilyClass?
        
        init?(_ base: FontFaceBase) {
            guard let fontName = base.fontName else { return nil }
            self.fontName = fontName
            self.displayName = base.displayName
            self.uniqueName = base.uniqueName
            self.familyName = base.familyName
            self.faceName = base.faceName
            self.familyClass = base.familyClass
        }
    }
}

extension Font {
    
    public enum FamilyClass {
        
        case oldStyleSerifs
        case transitionalSerifs
        case modernSerifs
        case clarendonSerifs
        case slabSerifs
        case freeformSerifs
        case sansSerif
        case ornamentals
        case scripts
        case symbolic
    }
}

extension Font : CustomStringConvertible {
    
    public var description: String {
        return "Font(name: \(self.fontName), pointSize: \(self.pointSize))"
    }
}

extension Font {
    
    public func with(size pointSize: Double) -> Font {
        return Font(font: self, size: pointSize)
    }
}

extension Font {
    
    private func _shape(glyph: Int) -> [Shape.Component] {
        if cache.glyphs[glyph] == nil {
            cache.glyphs[glyph] = base.shape(glyph: glyph).filter { $0.count != 0 }
        }
        return cache.glyphs[glyph]!
    }
    
    public func boundary(forGlyph glyph: Int) -> Rect {
        let _pointScale = self._pointScale
        let bound = self._shape(glyph: glyph).reduce(nil) { $0?.union($1.boundary) ?? $1.boundary } ?? Rect()
        return Rect(origin: bound.origin * _pointScale, size: bound.size * _pointScale)
    }
    
    public func shape(forGlyph glyph: Int) -> Shape {
        return Shape(self._shape(glyph: glyph).map { $0 * SDTransform.scale(_pointScale) })
    }
}

extension Font {
    
    public var numberOfGlyphs: Int {
        return base.numberOfGlyphs
    }
    
    public func glyph(with unicode: UnicodeScalar) -> Int {
        return base.glyph(unicode: unicode)
    }
    
    public func advanceWidth(forGlyph glyph: Int) -> Double {
        return base.advanceWidth(glyph: glyph) * _pointScale
    }
    public func advanceHeight(forGlyph glyph: Int) -> Double {
        return base.advanceHeight(glyph: glyph) * _pointScale
    }
    
    public var coveredCharacterSet: CharacterSet {
        if cache.coveredCharacterSet == nil {
            cache.coveredCharacterSet = base.coveredCharacterSet
        }
        return cache.coveredCharacterSet!
    }
}

extension Font {
    
    private var _pointScale: Double {
        return pointSize / unitsPerEm
    }
    
    public var ascender: Double {
        return base.ascender * _pointScale
    }
    public var descender: Double {
        return base.descender * _pointScale
    }
    public var lineGap: Double {
        return base.lineGap * _pointScale
    }
    
    public var verticalAscender: Double? {
        return base.verticalAscender.map { $0 * _pointScale }
    }
    public var verticalDescender: Double? {
        return base.verticalDescender.map { $0 * _pointScale }
    }
    public var verticalLineGap: Double? {
        return base.verticalLineGap.map { $0 * _pointScale }
    }
    
    public var unitsPerEm: Double {
        return base.unitsPerEm
    }
    
    public var boundingRectForFont: Rect {
        let _pointScale = self._pointScale
        let bound = base.boundingRectForFont
        return Rect(origin: bound.origin * _pointScale, size: bound.size * _pointScale)
    }
    
    public var italicAngle: Double {
        return base.italicAngle
    }
    public var weight: Int? {
        return base.weight
    }
    public var stretch: Int? {
        return base.stretch
    }
    public var isFixedPitch: Bool {
        return base.isFixedPitch
    }
    public var isItalic: Bool {
        return base.isItalic
    }
    public var isBold: Bool {
        return base.isBold
    }
    public var isExpanded: Bool {
        return base.isExpanded
    }
    public var isCondensed: Bool {
        return base.isCondensed
    }
    
    public var underlinePosition: Double {
        return base.underlinePosition * _pointScale
    }
    public var underlineThickness: Double {
        return base.underlineThickness * _pointScale
    }
}

extension Font {
    
    public var fontName: String {
        return details.fontName
    }
    public var displayName: String? {
        return details.displayName
    }
    public var uniqueName: String? {
        return details.uniqueName
    }
    public var familyName: String? {
        return details.familyName
    }
    public var faceName: String? {
        return details.faceName
    }
    
    public var familyClass: FamilyClass? {
        return details.familyClass
    }
    
    public var designer: String? {
        return base.designer
    }
    
    public var version: String? {
        return base.version
    }
    
    public var trademark: String? {
        return base.trademark
    }
    public var manufacturer: String? {
        return base.manufacturer
    }
    public var license: String? {
        return base.license
    }
    public var copyright: String? {
        return base.copyright
    }
    
}
