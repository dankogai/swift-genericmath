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
    public init(rawValue u128:UInt128) {
        self.value = u128
    }
    public init(_ d:Double) {
        value = UInt128(0)
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
    public init(_ f:Float) { self.init(Double(f)) }
    public var isSignMinus:Bool {
        return value.value.0 & 0x8000_0000 != 0
    }
    public var isZero:Bool {
        return (value.value.0 & 0x7fff_ffff) == 0
            && value.value.1 == 0 && value.value.2 == 0 && value.value.3 == 0
    }
    public var isInfinite:Bool {
        return (value.value.0 == 0x7fff_0000 ||  value.value.0 == 0xffff_0000)
            && value.value.1 == 0 && value.value.2 == 0 && value.value.3 == 0
    }
    public var isFinite:Bool {
        return !self.isInfinite
    }
    public static let infinity = Float128(rawValue:UInt128(0x7fff_0000, 0, 0, 0))
    public var isNaN:Bool {
        return (value.value.0 & 0x7fff_ffff == 0x7fff_0000)
            && (value.value.1 != 0 || value.value.2 != 0 || value.value.3 == 0)
    }
    public static let NaN = Float128(rawValue:UInt128(0x7fff_0000, 0x8000_0000, 0, 0))
    public static let quietNaN = Float128(rawValue:UInt128(0x7fff_0000, 0x8000_0000, 0, 0))
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
        var (result, ex) = m.frexp
        ex += e
        result.value.value.0 |= UInt32(ex - 1 + 0x3FFF) << 16
        return result
    }
}
public extension Double {
    public init(_ f128:Float128) {
        if f128.isZero {
            self = 0.0
        } else {
            let (m, e) = f128.frexp
            let mt = m.value >> 60
            var mu = (UInt64(mt.value.2 & 0x000f_ffff) << 32) | UInt64(mt.value.3)
            mu |= 0x3fe0_0000_0000_0000
            print("mu:", String(format:"%016lx", mu), "e:", e)
            self = Double.ldexp(unsafeBitCast(mu, Double.self), e)
        }
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

extension Float128: Equatable {}
public func == (lhs:Float128, rhs:Float128)->Bool {
    guard !lhs.isNaN && !rhs.isNaN else {
        return false
    }
    return lhs.value == rhs.value
}

extension Float128: Comparable {}
public func <(lhs:Float128, rhs:Float128)->Bool {
    if lhs.isSignMinus == rhs.isSignMinus {
        return lhs.abs.value < rhs.abs.value
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

