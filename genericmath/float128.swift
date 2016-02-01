//
//  float128.swift
//  genericmath
//
//  Created by Dan Kogai on 1/31/16.
//  Copyright © 2016 Dan Kogai. All rights reserved.
//

// cf. https://en.wikipedia.org/wiki/Quadruple-precision_floating-point_format

import Foundation
public struct Float128 {
    var value:UInt128
    public init() {
        value = UInt128(0)
    }
    public init(_ f128:Float128) {
        self.value = f128.value
    }
    public init(rawValue u128:UInt128) {
        self.value = u128
    }
    public init(_ d:Double) {
        if d.isNaN {
            self.init(Float128.NaN)
        } else if d.isInfinite {
            self.init(d.isSignMinus ? -Float128.infinity : +Float128.infinity)
        } else {
            self.init()
            if !d.isZero {
                let (m, e) = Double.frexp(d)
                value.value.0 |= UInt32( e - 1 + 0x3fff ) << 16
                let mb = unsafeBitCast(m, UInt64.self) & 0x000f_ffff_ffff_ffff
                // print(String(format:"%016lx", mb))
                // debugPrint(UInt128(mb) << 40)
                value |= UInt128(mb) << 60
            }
            if d.isSignMinus { self = -self }
        }
    }
    public init(_ f:Float) { self.init(Double(f)) }
    public var isSignMinus:Bool {
        return self.isNaN ? false : value.value.0 & 0x8000_0000 != 0
    }
    public var isZero:Bool {
        return (value.value.0 & 0x7fff_ffff == 0)
            && value.value.1 == 0 && value.value.2 == 0 && value.value.3 == 0
    }
    public var isInfinite:Bool {
        return (value.value.0 & 0x7fff_ffff == 0x7fff_0000)
            && value.value.1 == 0 && value.value.2 == 0 && value.value.3 == 0
    }
    public var isFinite:Bool {
        return !self.isInfinite
    }
    public static let infinity = Float128(rawValue:UInt128(0x7fff_0000, 0, 0, 0))
    public var isNaN:Bool {
        return value.value.0 == 0x7fff_8000
    }
    public static let NaN = Float128(rawValue:UInt128(0x7fff_8000, 0, 0, 0))
    public static let quietNaN = Float128(rawValue:UInt128(0x7fff_8000, 0, 0, 0))
    // as Double
    public var asDouble:Double {
        if self.isZero {
            return self.isSignMinus ? -0.0 : +0.0
        } else if self.isInfinite {
            return self.isSignMinus ? -Double.infinity : +Double.infinity
        } else if self.isNaN {
           return Double.NaN
        } else {
            let (m, e) = self.frexp
            let mt = m.value >> 60
            var mu = (UInt64(mt.value.2 & 0x000f_ffff) << 32) | UInt64(mt.value.3)
            mu |= 0x3fe0_0000_0000_0000
            // print("mu:", String(format:"%016lx", mu), "e:", e, "d:", unsafeBitCast(mu, Double.self))
            let result = Double.ldexp(unsafeBitCast(mu, Double.self), e)
            return self.isSignMinus ? -result : +result
        }
    }
    // no signal yet
    public var isSignaling:Bool { return false }
    // always normal for the time being
    public var isNormal:Bool { return true }
    public var isSubnormal:Bool { return !self.isNormal }
    //
    public var floatingPointClass:FloatingPointClassification {
        if self.isZero {
            return self.isSignMinus ? .NegativeZero : .PositiveZero
        }
        if self.isInfinite {
            return self.isSignMinus ? .NegativeInfinity : .PositiveInfinity
        }
        if self.isNaN {
            return .QuietNaN
        }
        return self.isSignMinus ? .NegativeNormal : .PositiveNormal
    }
    // decompose Float128
    public var frexp:(Float128, Int) {
        if self.isZero || self.isInfinite || self.isNaN {
            return (self, 0)
        }
        let e = Int((self.value.value.0 >> 16) & 0x7fff)
        var m = self.value & UInt128(0x8000ffff,0xffffFFFF,0xffffFFFF,0xffffFFFF)
        m.value.0 |= 0x3ffe_0000
        if self.isSignMinus { m.value.0 |= 0x8000_0000 }
        return (Float128(rawValue:m), e + 1 - 0x3FFF)
    }
    // compose Float128
    public static func ldexp(m:Float128, _ e:Int)->Float128 {
        if m.isZero || m.isInfinite || m.isNaN {
            return m
        }
        var result = m.frexp.0
        result.value.value.0 &= 0x8000_ffff
        result.value.value.0 |= UInt32(e - 1 + 0x3FFF) << 16
        return result
    }
    //
    public var isPowerOf2:Bool {
        return (value.value.0 & 0x7fff_ffff == 0x7fff_0000) // not inf or nan
            && value.value.0 & 0x0000ffff == 0
            && value.value.1 == 0 && value.value.2 == 0 && value.value.3 == 0
    }
    static let mmask = ~UInt128(0xffff0000,0,0,0)
    static let sbits = 110
}
public extension Double {
    public init(_ f128:Float128) { self = f128.asDouble }
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

extension Float128: Equatable {}
public func == (lhs:Float128, rhs:Float128)->Bool {
    if lhs.isZero && rhs.isZero {
        return true
    }
    if lhs.isInfinite && rhs.isInfinite {
        return lhs.isSignMinus == rhs.isSignMinus
    }
    if lhs.isNaN || rhs.isNaN {
        return false
    }
    return lhs.value == rhs.value
}

extension Float128: Comparable {}
public func <(lhs:Float128, rhs:Float128)->Bool {
    if lhs.isSignMinus == rhs.isSignMinus {
        let (ml, el) = lhs.frexp
        let (mr, er) = rhs.frexp
        if el == er {
            return lhs.isSignMinus
                ? ml.abs.value > mr.abs.value
                : ml.abs.value < mr.abs.value
        } else {
            return lhs.isSignMinus
                ? el > er
                : el < er
        }
    }
    return lhs.isSignMinus ? true : false
}

extension Float128: IntegerLiteralConvertible {
    public typealias IntegerLiteralType = Double.IntegerLiteralType
    public init(integerLiteral value:IntegerLiteralType) {
        self.init(Double(value))
    }
}

extension Float128: SignedNumberType {}
public prefix func + (f128:Float128)->Float128 {
    return f128
}
public prefix func - (f128:Float128)->Float128 {
    guard !f128.isNaN else { return f128 }
    var result = f128
    result.value.value.0 |= 0x8000_0000
    return result
}
public func - (lhs:Float128, rhs:Float128)->Float128 {
    fatalError("unimplemented")
}
extension Float128: AbsoluteValuable {
    public var abs:Float128 {
        return self.isSignMinus ? -self : self
    }
    public static func abs(x: Float128) -> Float128 {
        return x.abs
    }
}
extension Float128 : FloatingPointType {
    public init(_ i:Int)      { self.init(Double(i)) }
    public init(_ i:Int16)    { self.init(Double(i)) }
    public init(_ i:Int32)    { self.init(Double(i)) }
    public init(_ i:Int64)    { self.init(Double(i)) }
    public init(_ i:Int8)     { self.init(Double(i)) }
    public init(_ u:UInt)     { self.init(Double(u)) }
    public init(_ u:UInt16)   { self.init(Double(u)) }
    public init(_ u:UInt32)   { self.init(Double(u)) }
    public init(_ u:UInt64)   { self.init(Double(u)) }
    public init(_ u:UInt8)    { self.init(Double(u)) }
    public typealias _BitsType = UInt128
    public typealias Stride = Float128
    public func advancedBy(n:Stride)->Float128 {
        fatalError("unimplemented")
    }
    public func distanceTo(other:Float128) -> Stride {
        fatalError("unimplemented")
    }
    public static func _fromBitPattern(bits: _BitsType) -> Float128 {
        return Float128(rawValue: bits)
    }
    public func _toBitPattern()->_BitsType {
        return self.value
    }
}
public func + (lhs:Float128, rhs:Float128)->Float128 {
    fatalError("unimplemented")
    /*
    let (ml, el) = lhs.frexp
    let (mr, er) = rhs.frexp
    var vl = ml.value & Float128.mmask
    var vr = mr.value & Float128.mmask
    let shift = el - er
    var e = el
    print("vl=\(vl.toString(16)), vr=\(vr.toString(16)), el=\(el), er=\(er),shift=\(shift)")
    if (shift < 0) {
        if shift > Float128.sbits { return rhs }
        e = er
        vl >>= UInt32(-shift)
    } else if (shift > 0) {
        if shift > Float128.sbits { return lhs }
        e = el
        vr >>= UInt32(+shift)
    }
    print("vl=\(vl.toString(16)), vr=\(vr.toString(16)), e=\(e)")
    var v = vl + vr
    v.value.0 += 0x00008000 // implicit one
    print(" v=\(v.toString(16))")
    v.value.0 |= 0x3ffe_0000
    print(" v=\(v.toString(16)), e-1=\(e-1)")
    print(Float128(rawValue: v).asDouble)
    let result = Float128.ldexp(Float128(rawValue: v), e)
    return result
    */
}
public func * (lhs:Float128, rhs:Float128)->Float128 {
    let (ml, el) = lhs.frexp
    let (mr, er) = rhs.frexp
    if lhs.isPowerOf2 {
        return Float128.ldexp(mr, el+er)
    }
    if rhs.isPowerOf2 {
        return Float128.ldexp(ml, el+er)
    }
    //       Implicit 1         Half mantissa
    let vl = UInt128(1) << 56 | (ml.value & Float128.mmask) >> 56
    let vr = UInt128(1) << 56 | (mr.value & Float128.mmask) >> 56
    var v = vl * vr
    var e = el + er + 0x3fff - 2    // -2 to offset implicit 1
    if v.msb > 112 {
        v >>= UInt32(1)
        e += 1
    }
    v.value.0 &= 0x0000_ffff
    v.value.0 |= UInt32(e) << 16
    let isSignMinus = lhs.isSignMinus
        ? rhs.isSignMinus ? false : true
        : rhs.isSignMinus ? true : false
    return isSignMinus ? -Float128(rawValue:v) : +Float128(rawValue:v)
}
public func / (lhs:Float128, rhs:Float128)->Float128 {
    fatalError("unimplemented")
}
public func % (lhs:Float128, rhs:Float128)->Float128 {
    fatalError("unimplemented")
}
