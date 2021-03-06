//
//  JPEGDCT.swift
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

@inline(__always)
private func JPEGFDCT<T: BinaryFloatingPoint>(_ a1: T, _ h1: T, _ e1: T, _ d1: T, _ c1: T, _ f1: T, _ g1: T, _ b1: T) -> (T, T, T, T, T, T, T, T) {

    let a3 = a1 + b1
    let b3 = a1 - b1
    let c3 = c1 + d1
    let d3 = c1 - d1
    let e3 = e1 + f1
    let f3 = e1 - f1
    let g3 = g1 + h1
    let h3 = g1 - h1

    let a5 = a3 + c3
    let c5 = a3 - c3
    let e5 = e3 + g3
    let g5 = e3 - g3

    let M_SQRT1_2 = 0.7071067811865475244008443621048490392848359376884740 as T

    let i = M_SQRT1_2 * (f3 - h3)
    let j = M_SQRT1_2 * (f3 + h3)

    let a7 = a5 + e5
    let b7 = a5 - e5
    let c7 = b3 + i
    let d7 = d3 + j
    let g7 = b3 - i
    let h7 = d3 - j

    let C1 = 1.3870398453221474618216191915664386311134980027420540 as T
    let C2 = 1.3065629648763765278566431734271871535837611883492695 as T
    let C3 = 1.1758756024193587169744671046112612779016253486452909 as T
    let S1 = 0.2758993792829430123359575636693728823636236212324459 as T
    let S2 = 0.5411961001461969843997232053663894200610720633780154 as T
    let S3 = 0.7856949583871021812778973676572167960462421131413813 as T

    return (
        a7,
        c7 * C1 - d7 * S1,
        c5 * C2 - g5 * S2,
        g7 * C3 + h7 * S3,
        b7,
        g7 * S3 - h7 * C3,
        c5 * S2 + g5 * C2,
        c7 * S1 + d7 * C1
    )
}

@inline(__always)
private func JPEGIDCT<T: BinaryFloatingPoint>(_ i0: T, _ i1: T, _ i2: T, _ i3: T, _ i4: T, _ i5: T, _ i6: T, _ i7: T) -> (T, T, T, T, T, T, T, T) {

    let C1 = 0.6935199226610737309108095957832193155567490013710270 as T
    let C2 = 0.6532814824381882639283215867135935767918805941746348 as T
    let C3 = 0.5879378012096793584872335523056306389508126743226455 as T
    let S1 = 0.1379496896414715061679787818346864411818118106162230 as T
    let S2 = 0.2705980500730984921998616026831947100305360316890077 as T
    let S3 = 0.3928474791935510906389486838286083980231210565706906 as T

    let a1 = i0
    let b1 = i4
    let e1 = i1 * C1 + i7 * S1
    let e2 = i1 * S1 - i7 * C1
    let c1 = i2 * C2 + i6 * S2
    let c2 = i2 * S2 - i6 * C2
    let g1 = i3 * C3 + i5 * S3
    let g2 = i3 * S3 - i5 * C3

    let a3 = a1 + b1
    let b3 = a1 - b1
    let c3 = c1 + c1
    let d4 = c2 + c2
    let e3 = e1 + g1
    let e4 = e2 - g2
    let f3 = e1 - g1
    let f4 = e2 + g2
    let g3 = g1 + e1
    let g4 = g2 - e2
    let h3 = g1 - e1
    let h4 = g2 + e2

    let a5 = a3 + c3
    let b5 = b3 - d4
    let c5 = a3 - c3
    let d5 = b3 + d4
    let e5 = e3 + g3
    let f5 = f3 - h4
    let f6 = f4 + h3
    let g6 = e4 - g4
    let h5 = f3 + h4
    let h6 = f4 - h3

    let M_SQRT1_2 = 0.7071067811865475244008443621048490392848359376884740 as T

    let i = M_SQRT1_2 * (f5 - f6)
    let k = M_SQRT1_2 * (h5 + h6)

    return (
        a5 + e5,
        d5 + k,
        b5 + i,
        c5 + g6,
        c5 - g6,
        b5 - i,
        d5 - k,
        a5 - e5
    )
}

struct JPEG_DCT_BLOCK<T: FixedWidthInteger> {

    var r0: (T, T, T, T, T, T, T, T)
    var r1: (T, T, T, T, T, T, T, T)
    var r2: (T, T, T, T, T, T, T, T)
    var r3: (T, T, T, T, T, T, T, T)
    var r4: (T, T, T, T, T, T, T, T)
    var r5: (T, T, T, T, T, T, T, T)
    var r6: (T, T, T, T, T, T, T, T)
    var r7: (T, T, T, T, T, T, T, T)

    init(_ r0: (T, T, T, T, T, T, T, T),
         _ r1: (T, T, T, T, T, T, T, T),
         _ r2: (T, T, T, T, T, T, T, T),
         _ r3: (T, T, T, T, T, T, T, T),
         _ r4: (T, T, T, T, T, T, T, T),
         _ r5: (T, T, T, T, T, T, T, T),
         _ r6: (T, T, T, T, T, T, T, T),
         _ r7: (T, T, T, T, T, T, T, T)) {
        self.r0 = r0
        self.r1 = r1
        self.r2 = r2
        self.r3 = r3
        self.r4 = r4
        self.r5 = r5
        self.r6 = r6
        self.r7 = r7
    }

    init<S: BinaryFloatingPoint>(_ r0: (S, S, S, S, S, S, S, S),
                                 _ r1: (S, S, S, S, S, S, S, S),
                                 _ r2: (S, S, S, S, S, S, S, S),
                                 _ r3: (S, S, S, S, S, S, S, S),
                                 _ r4: (S, S, S, S, S, S, S, S),
                                 _ r5: (S, S, S, S, S, S, S, S),
                                 _ r6: (S, S, S, S, S, S, S, S),
                                 _ r7: (S, S, S, S, S, S, S, S)) {
        let _max = S(T.max)
        let _min = S(T.min)
        self.r0 = (T(max(_min, min(_max, r0.0.rounded()))), T(max(_min, min(_max, r0.1.rounded()))), T(max(_min, min(_max, r0.2.rounded()))), T(max(_min, min(_max, r0.3.rounded()))),
                   T(max(_min, min(_max, r0.4.rounded()))), T(max(_min, min(_max, r0.5.rounded()))), T(max(_min, min(_max, r0.6.rounded()))), T(max(_min, min(_max, r0.7.rounded()))))
        self.r1 = (T(max(_min, min(_max, r1.0.rounded()))), T(max(_min, min(_max, r1.1.rounded()))), T(max(_min, min(_max, r1.2.rounded()))), T(max(_min, min(_max, r1.3.rounded()))),
                   T(max(_min, min(_max, r1.4.rounded()))), T(max(_min, min(_max, r1.5.rounded()))), T(max(_min, min(_max, r1.6.rounded()))), T(max(_min, min(_max, r1.7.rounded()))))
        self.r2 = (T(max(_min, min(_max, r2.0.rounded()))), T(max(_min, min(_max, r2.1.rounded()))), T(max(_min, min(_max, r2.2.rounded()))), T(max(_min, min(_max, r2.3.rounded()))),
                   T(max(_min, min(_max, r2.4.rounded()))), T(max(_min, min(_max, r2.5.rounded()))), T(max(_min, min(_max, r2.6.rounded()))), T(max(_min, min(_max, r2.7.rounded()))))
        self.r3 = (T(max(_min, min(_max, r3.0.rounded()))), T(max(_min, min(_max, r3.1.rounded()))), T(max(_min, min(_max, r3.2.rounded()))), T(max(_min, min(_max, r3.3.rounded()))),
                   T(max(_min, min(_max, r3.4.rounded()))), T(max(_min, min(_max, r3.5.rounded()))), T(max(_min, min(_max, r3.6.rounded()))), T(max(_min, min(_max, r3.7.rounded()))))
        self.r4 = (T(max(_min, min(_max, r4.0.rounded()))), T(max(_min, min(_max, r4.1.rounded()))), T(max(_min, min(_max, r4.2.rounded()))), T(max(_min, min(_max, r4.3.rounded()))),
                   T(max(_min, min(_max, r4.4.rounded()))), T(max(_min, min(_max, r4.5.rounded()))), T(max(_min, min(_max, r4.6.rounded()))), T(max(_min, min(_max, r4.7.rounded()))))
        self.r5 = (T(max(_min, min(_max, r5.0.rounded()))), T(max(_min, min(_max, r5.1.rounded()))), T(max(_min, min(_max, r5.2.rounded()))), T(max(_min, min(_max, r5.3.rounded()))),
                   T(max(_min, min(_max, r5.4.rounded()))), T(max(_min, min(_max, r5.5.rounded()))), T(max(_min, min(_max, r5.6.rounded()))), T(max(_min, min(_max, r5.7.rounded()))))
        self.r6 = (T(max(_min, min(_max, r6.0.rounded()))), T(max(_min, min(_max, r6.1.rounded()))), T(max(_min, min(_max, r6.2.rounded()))), T(max(_min, min(_max, r6.3.rounded()))),
                   T(max(_min, min(_max, r6.4.rounded()))), T(max(_min, min(_max, r6.5.rounded()))), T(max(_min, min(_max, r6.6.rounded()))), T(max(_min, min(_max, r6.7.rounded()))))
        self.r7 = (T(max(_min, min(_max, r7.0.rounded()))), T(max(_min, min(_max, r7.1.rounded()))), T(max(_min, min(_max, r7.2.rounded()))), T(max(_min, min(_max, r7.3.rounded()))),
                   T(max(_min, min(_max, r7.4.rounded()))), T(max(_min, min(_max, r7.5.rounded()))), T(max(_min, min(_max, r7.6.rounded()))), T(max(_min, min(_max, r7.7.rounded()))))
    }
}

extension JPEG_DCT_BLOCK {

    func FDCT() -> JPEG_DCT_BLOCK {

        let c0 = JPEGFDCT(Double(r0.0), Double(r0.1), Double(r0.2), Double(r0.3), Double(r0.4), Double(r0.5), Double(r0.6), Double(r0.7))
        let c1 = JPEGFDCT(Double(r1.0), Double(r1.1), Double(r1.2), Double(r1.3), Double(r1.4), Double(r1.5), Double(r1.6), Double(r1.7))
        let c2 = JPEGFDCT(Double(r2.0), Double(r2.1), Double(r2.2), Double(r2.3), Double(r2.4), Double(r2.5), Double(r2.6), Double(r2.7))
        let c3 = JPEGFDCT(Double(r3.0), Double(r3.1), Double(r3.2), Double(r3.3), Double(r3.4), Double(r3.5), Double(r3.6), Double(r3.7))
        let c4 = JPEGFDCT(Double(r4.0), Double(r4.1), Double(r4.2), Double(r4.3), Double(r4.4), Double(r4.5), Double(r4.6), Double(r4.7))
        let c5 = JPEGFDCT(Double(r5.0), Double(r5.1), Double(r5.2), Double(r5.3), Double(r5.4), Double(r5.5), Double(r5.6), Double(r5.7))
        let c6 = JPEGFDCT(Double(r6.0), Double(r6.1), Double(r6.2), Double(r6.3), Double(r6.4), Double(r6.5), Double(r6.6), Double(r6.7))
        let c7 = JPEGFDCT(Double(r7.0), Double(r7.1), Double(r7.2), Double(r7.3), Double(r7.4), Double(r7.5), Double(r7.6), Double(r7.7))

        let d0 = JPEGFDCT(c0.0, c1.0, c2.0, c3.0, c4.0, c5.0, c6.0, c7.0)
        let d1 = JPEGFDCT(c0.1, c1.1, c2.1, c3.1, c4.1, c5.1, c6.1, c7.1)
        let d2 = JPEGFDCT(c0.2, c1.2, c2.2, c3.2, c4.2, c5.2, c6.2, c7.2)
        let d3 = JPEGFDCT(c0.3, c1.3, c2.3, c3.3, c4.3, c5.3, c6.3, c7.3)
        let d4 = JPEGFDCT(c0.4, c1.4, c2.4, c3.4, c4.4, c5.4, c6.4, c7.4)
        let d5 = JPEGFDCT(c0.5, c1.5, c2.5, c3.5, c4.5, c5.5, c6.5, c7.5)
        let d6 = JPEGFDCT(c0.6, c1.6, c2.6, c3.6, c4.6, c5.6, c6.6, c7.6)
        let d7 = JPEGFDCT(c0.7, c1.7, c2.7, c3.7, c4.7, c5.7, c6.7, c7.7)

        return JPEG_DCT_BLOCK(
            (d0.0 * 0.125, d1.0 * 0.125, d2.0 * 0.125, d3.0 * 0.125, d4.0 * 0.125, d5.0 * 0.125, d6.0 * 0.125, d7.0 * 0.125),
            (d0.1 * 0.125, d1.1 * 0.125, d2.1 * 0.125, d3.1 * 0.125, d4.1 * 0.125, d5.1 * 0.125, d6.1 * 0.125, d7.1 * 0.125),
            (d0.2 * 0.125, d1.2 * 0.125, d2.2 * 0.125, d3.2 * 0.125, d4.2 * 0.125, d5.2 * 0.125, d6.2 * 0.125, d7.2 * 0.125),
            (d0.3 * 0.125, d1.3 * 0.125, d2.3 * 0.125, d3.3 * 0.125, d4.3 * 0.125, d5.3 * 0.125, d6.3 * 0.125, d7.3 * 0.125),
            (d0.4 * 0.125, d1.4 * 0.125, d2.4 * 0.125, d3.4 * 0.125, d4.4 * 0.125, d5.4 * 0.125, d6.4 * 0.125, d7.4 * 0.125),
            (d0.5 * 0.125, d1.5 * 0.125, d2.5 * 0.125, d3.5 * 0.125, d4.5 * 0.125, d5.5 * 0.125, d6.5 * 0.125, d7.5 * 0.125),
            (d0.6 * 0.125, d1.6 * 0.125, d2.6 * 0.125, d3.6 * 0.125, d4.6 * 0.125, d5.6 * 0.125, d6.6 * 0.125, d7.6 * 0.125),
            (d0.7 * 0.125, d1.7 * 0.125, d2.7 * 0.125, d3.7 * 0.125, d4.7 * 0.125, d5.7 * 0.125, d6.7 * 0.125, d7.7 * 0.125)
        )
    }

    func IDCT() -> JPEG_DCT_BLOCK {

        let c0 = JPEGIDCT(Double(r0.0), Double(r0.1), Double(r0.2), Double(r0.3), Double(r0.4), Double(r0.5), Double(r0.6), Double(r0.7))
        let c1 = JPEGIDCT(Double(r1.0), Double(r1.1), Double(r1.2), Double(r1.3), Double(r1.4), Double(r1.5), Double(r1.6), Double(r1.7))
        let c2 = JPEGIDCT(Double(r2.0), Double(r2.1), Double(r2.2), Double(r2.3), Double(r2.4), Double(r2.5), Double(r2.6), Double(r2.7))
        let c3 = JPEGIDCT(Double(r3.0), Double(r3.1), Double(r3.2), Double(r3.3), Double(r3.4), Double(r3.5), Double(r3.6), Double(r3.7))
        let c4 = JPEGIDCT(Double(r4.0), Double(r4.1), Double(r4.2), Double(r4.3), Double(r4.4), Double(r4.5), Double(r4.6), Double(r4.7))
        let c5 = JPEGIDCT(Double(r5.0), Double(r5.1), Double(r5.2), Double(r5.3), Double(r5.4), Double(r5.5), Double(r5.6), Double(r5.7))
        let c6 = JPEGIDCT(Double(r6.0), Double(r6.1), Double(r6.2), Double(r6.3), Double(r6.4), Double(r6.5), Double(r6.6), Double(r6.7))
        let c7 = JPEGIDCT(Double(r7.0), Double(r7.1), Double(r7.2), Double(r7.3), Double(r7.4), Double(r7.5), Double(r7.6), Double(r7.7))

        let d0 = JPEGIDCT(c0.0, c1.0, c2.0, c3.0, c4.0, c5.0, c6.0, c7.0)
        let d1 = JPEGIDCT(c0.1, c1.1, c2.1, c3.1, c4.1, c5.1, c6.1, c7.1)
        let d2 = JPEGIDCT(c0.2, c1.2, c2.2, c3.2, c4.2, c5.2, c6.2, c7.2)
        let d3 = JPEGIDCT(c0.3, c1.3, c2.3, c3.3, c4.3, c5.3, c6.3, c7.3)
        let d4 = JPEGIDCT(c0.4, c1.4, c2.4, c3.4, c4.4, c5.4, c6.4, c7.4)
        let d5 = JPEGIDCT(c0.5, c1.5, c2.5, c3.5, c4.5, c5.5, c6.5, c7.5)
        let d6 = JPEGIDCT(c0.6, c1.6, c2.6, c3.6, c4.6, c5.6, c6.6, c7.6)
        let d7 = JPEGIDCT(c0.7, c1.7, c2.7, c3.7, c4.7, c5.7, c6.7, c7.7)

        return JPEG_DCT_BLOCK(
            (d0.0 * 0.125, d1.0 * 0.125, d2.0 * 0.125, d3.0 * 0.125, d4.0 * 0.125, d5.0 * 0.125, d6.0 * 0.125, d7.0 * 0.125),
            (d0.1 * 0.125, d1.1 * 0.125, d2.1 * 0.125, d3.1 * 0.125, d4.1 * 0.125, d5.1 * 0.125, d6.1 * 0.125, d7.1 * 0.125),
            (d0.2 * 0.125, d1.2 * 0.125, d2.2 * 0.125, d3.2 * 0.125, d4.2 * 0.125, d5.2 * 0.125, d6.2 * 0.125, d7.2 * 0.125),
            (d0.3 * 0.125, d1.3 * 0.125, d2.3 * 0.125, d3.3 * 0.125, d4.3 * 0.125, d5.3 * 0.125, d6.3 * 0.125, d7.3 * 0.125),
            (d0.4 * 0.125, d1.4 * 0.125, d2.4 * 0.125, d3.4 * 0.125, d4.4 * 0.125, d5.4 * 0.125, d6.4 * 0.125, d7.4 * 0.125),
            (d0.5 * 0.125, d1.5 * 0.125, d2.5 * 0.125, d3.5 * 0.125, d4.5 * 0.125, d5.5 * 0.125, d6.5 * 0.125, d7.5 * 0.125),
            (d0.6 * 0.125, d1.6 * 0.125, d2.6 * 0.125, d3.6 * 0.125, d4.6 * 0.125, d5.6 * 0.125, d6.6 * 0.125, d7.6 * 0.125),
            (d0.7 * 0.125, d1.7 * 0.125, d2.7 * 0.125, d3.7 * 0.125, d4.7 * 0.125, d5.7 * 0.125, d6.7 * 0.125, d7.7 * 0.125)
        )
    }
}
