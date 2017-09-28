//
//  DGXMLParser.swift
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

extension DGXMLDocument {
    
    enum Error : Swift.Error {
        
        case unknown
        case parser(String)
    }
    
    public init(xml string: String) throws {
        guard let data = string.data(using: .utf8) else { throw Error.unknown }
        try self.init(data: data)
    }
    
    public init(data: Data) throws {
        let parser = DGXMLParser(data: data)
        guard parser.parse() else { throw parser.parserError.map { Error.parser($0.localizedDescription) } ?? Error.unknown }
        self = parser.document
    }
}

class DGXMLParser : XMLParser, XMLParserDelegate {
    
    var document = DGXMLDocument()
    var stack: [DGXMLElement] = []
    var namespaces: [String: String] = [:]
    
    override init(data: Data) {
        super.init(data: data)
        self.delegate = self
        self.shouldProcessNamespaces = true
        self.shouldReportNamespacePrefixes = true
    }
    
    func parser(_ parser: XMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String) {
        namespaces[prefix] = namespaceURI
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        var attributeDict = attributeDict
        for (prefix, uri) in namespaces {
            attributeDict[prefix == "" ? "xmlns" : "xmlns:\(prefix)"] = uri
        }
        namespaces = [:]
        
        stack.append(DGXMLElement(name: elementName, namespace: namespaceURI, attributes: attributeDict))
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let last = stack.popLast() {
            if stack.count == 0 {
                document.append(last)
            } else {
                stack[stack.count - 1].append(last)
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        let string = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if string != "" {
            if stack.count == 0 {
                document.append(DGXMLElement(characters: string))
            } else {
                stack[stack.count - 1].append(DGXMLElement(characters: string))
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundComment comment: String) {
        if stack.count == 0 {
            document.append(DGXMLElement(comment: comment))
        } else {
            stack[stack.count - 1].append(DGXMLElement(comment: comment))
        }
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if stack.count == 0 {
            document.append(DGXMLElement(CDATA: String(data: CDATABlock, encoding: .utf8) ?? ""))
        } else {
            stack[stack.count - 1].append(DGXMLElement(CDATA: String(data: CDATABlock, encoding: .utf8) ?? ""))
        }
    }
}