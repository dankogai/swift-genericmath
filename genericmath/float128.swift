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
    import Darwin
#endif
public extension Double {
    #if os(Linux)
    public static func frexp(d:Double)->(Double, Int) { return Glibc.frexp(d) }
    #else
    public static func frexp(d:Double)->(Double, Int)   { return Darwin.frexp(d) }
    public static func ldexp(m:Double, _ e:Int)->Double { return Darwin.ldexp(m, e) }
    #endif
}
import Foundation

public struct Float128 {
    var value:UInt128
    public init(_ f128:Float128) {
        self.value = f128.value
    }
    public init(_ u128:UInt128) {
        self.value = u128
    }
    public init(_ d:Double) {
        value = UInt128(0)
        let (m, e) = Double.frexp(d)
        if m.isSignMinus { value.value.0 = 0x8000_0000 }
        value.value.0 |= UInt32( e - 1 + 0x3fff ) << 16
        let mb = unsafeBitCast(m, UInt64.self) & 0x000f_ffff_ffff_ffff
        // print(String(format:"%016lx", mb))
        // debugPrint(UInt128(mb) << 40)
        value |= UInt128(mb) << 60
    }
    public var isSignMinus:Bool {
        return value.value.0 & 0x8000_0000 != 0
    }
    public var isZero:Bool {
        return (value.value.0 & 0x7fff_ffff) == 0
            && value.value.1 == 0 && value.value.2 == 0 && value.value.3 == 0
    }
    public var frexp:(Float128, Int) {
        if self.isZero { return (self, 0) }
        let e = Int((self.value.value.0 >> 16) & 0x7fff)
        var m = self.value & UInt128(0x8000ffff,0xffffFFFF,0xffffFFFF,0xffffFFFF)
        m.value.0 |= 0x3ffe_0000
        if self.isSignMinus { m.value.0 |= 0x8000_0000 }
        return (Float128(m), e + 1 - 0x3FFF)
    }
}
public extension Double {
    public init(_ f128:Float128) {
        let (m, e) = f128.frexp
        let mt = m.value >> 60
        var mu = (UInt64(mt.value.2 & 0x000f_ffff) << 32) | UInt64(mt.value.3)
        mu |= 0x3fe0_0000_0000_0000
        print("mu:", String(format:"%016lx", mu), "e:", e)
        self = Double.ldexp(unsafeBitCast(mu, Double.self), e)
        if f128.isSignMinus { self *= -1 }
    }
}

extension Float128 : CustomDebugStringConvertible, CustomStringConvertible  {
    public var debugDescription:String {
        let a = [value.value.0,value.value.1,value.value.2,value.value.3]
        return a.map{String(format:"%08x",$0)}.joinWithSeparator(",")
    }
    public var description:String {
        return self.debugDescription
    }
}
