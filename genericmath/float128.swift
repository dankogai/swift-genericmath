//
//  float128.swift
//  genericmath
//
//  Created by Dan Kogai on 1/31/16.
//  Copyright © 2016 Dan Kogai. All rights reserved.
//

// cf. https://en.wikipedia.org/wiki/Quadruple-precision_floating-point_format

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

public struct Float128 {
    var value:UInt128
    public init(_ d:Double) {
        value = UInt128(0)
        let (m, e) = frexp(d)
        if m.isSignMinus { value.value.0 = 0x8000_0000 }
        value.value.0 |= UInt32( e - 1 + 0x3fff ) << 16
        let mb = unsafeBitCast(m, UInt64.self) & 0x000f_ffff_ffff_ffff
        print(String(format:"%016lx", mb))
        debugPrint(UInt128(mb) << 40)
        value |= UInt128(mb) << 60
    }
}

extension Float128 : CustomDebugStringConvertible  {
    public var debugDescription:String {
        let a = [value.value.0,value.value.1,value.value.2,value.value.3]
        return a.map{String(format:"%08x",$0)}.joinWithSeparator(",")
    }
}