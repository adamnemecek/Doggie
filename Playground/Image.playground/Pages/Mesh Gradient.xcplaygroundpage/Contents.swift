//: Playground - noun: a place where people can play

import Cocoa
import Doggie

let t = Date()

let image = sampleImage(width: 400, height: 400)

t.timeIntervalSinceNow

if let image = image.cgImage {
    NSImage(cgImage: image)
}