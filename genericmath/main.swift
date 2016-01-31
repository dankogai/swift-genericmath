//
//  main.swift
//  genericmath
//
//  Created by Dan Kogai on 1/30/16.
//  Copyright © 2016 Dan Kogai. All rights reserved.
//
let test = TAP()
print("#### UInt128")
test.eq(UInt128.min.description, "0", "UInt128.min == 0")
test.eq(UInt128("0"), UInt128.min,    "Unt128(\"0\") == UInt128.min")
let u128maxS = "340282366920938463463374607431768211455"
test.eq(UInt128.max.description, u128maxS, "UInt128.max == \(u128maxS)")
test.eq(UInt128(u128maxS), UInt128.max, "UInt128(\"\(u128maxS)\") == UInt128.max")
let palindromeI  = UInt128(0x0123456789abcdef, 0xfedcba9876543210)
let palindromeS =  "123456789abcdeffedcba9876543210"
test.eq(palindromeI.toString(16), palindromeS, "0x\"\(palindromeS)\"")
test.eq(UInt128(palindromeS, base:16), palindromeI, "UInt128(\"\(palindromeS)\",base:16)")
let u128maxDS = "UInt128(\"ffffffffffffffffffffffffffffffff\",base:16)"
test.eq(UInt128.max.debugDescription, u128maxDS, u128maxDS)
print("#### Int128")
let i128minS = "-170141183460469231731687303715884105728"
let i128maxS = "170141183460469231731687303715884105727"
test.eq(Int128.min.description, i128minS, "Int128.min == \(i128minS)")
test.eq(Int128(i128minS), Int128.min, "Int128(\"\(i128minS)\") == Int128.min")
test.eq(Int128.max.description, i128maxS, "Int128.max == \(i128maxS)")
test.eq(Int128(i128maxS), Int128.max, "Int128(\"\(i128maxS)\") == Int128.max")
test.eq(Int128("+"+i128maxS), Int128.max, "Int128(\"+\(i128maxS)\") == Int128.max")
let i128minDS = "Int128(\"-80000000000000000000000000000000\",base:16)"
let i128maxDS = "Int128(\"7fffffffffffffffffffffffffffffff\",base:16)"
test.eq(Int128.min.debugDescription, i128minDS, i128minDS)
test.eq(Int128.max.debugDescription, i128maxDS, i128maxDS)
test.eq(Int128.min + Int128.max, Int128(-1),    "Int128.min + Int128.max == -1")
test.ok(Int128.min < Int128.max, "Int128.min < Int128.max")
test.ok(abs(Int128.min+Int128(1)) > abs(Int128.max-Int128(1)),   "abs(Int128.min+1) > abs(Int128.max-1)")
let int64maxSQ = Int128("85070591730234615847396907784232501249")
test.eq(+Int128(Int64.max) * +Int128(Int64.max), +int64maxSQ, "+ * + == +")
test.eq(+Int128(Int64.max) * -Int128(Int64.max), -int64maxSQ, "+ * - == -")
test.eq(-Int128(Int64.max) * +Int128(Int64.max), -int64maxSQ, "- * + == -")
test.eq(-Int128(Int64.max) * -Int128(Int64.max), +int64maxSQ, "- * - == +")
let m31 = Int64(Int32.max)
let f5 = Int64(UInt16.max) + Int64(2)
test.eq(+Int128(m31) / +Int128(f5), Int128(+m31 / +f5), "+m31 / +f5 == \(+m31 / +f5)")
test.eq(+Int128(m31) % +Int128(f5), Int128(+m31 % +f5), "+m31 % +f5 == \(+m31 % +f5)")
test.eq(+Int128(m31) / -Int128(f5), Int128(+m31 / -f5), "+m31 / -f5 == \(+m31 / -f5)")
test.eq(+Int128(m31) % -Int128(f5), Int128(+m31 % -f5), "+m31 % -f5 == \(+m31 % -f5)")
test.eq(-Int128(m31) / +Int128(f5), Int128(-m31 / +f5), "-m31 / +f5 == \(-m31 / +f5)")
test.eq(-Int128(m31) % +Int128(f5), Int128(-m31 % +f5), "-m31 % +f5 == \(-m31 % +f5)")
test.eq(-Int128(m31) / -Int128(f5), Int128(-m31 / -f5), "-m31 / -f5 == \(-m31 / -f5)")
test.eq(-Int128(m31) % -Int128(f5), Int128(-m31 % -f5), "-m31 % -f5 == \(-m31 % -f5)")
let pp127 = Int128("170141183460469231731687303715884105703")
let pp95  = Int128("39614081257132168796771975153")
let aqo127_95 = Int128(4294967296)
let aro127_95 = Int128(64424509415)
test.eq(+Int128(pp127) / +Int128(pp95), +Int128(aqo127_95), "+\(pp127) / \(pp95) +\(aqo127_95)")
test.eq(+Int128(pp127) % +Int128(pp95), +Int128(aro127_95), "+\(pp127) % \(pp95) +\(aro127_95)")
test.eq(+Int128(pp127) / -Int128(pp95), -Int128(aqo127_95), "+\(pp127) / \(pp95) -\(aqo127_95)")
test.eq(+Int128(pp127) % -Int128(pp95), +Int128(aro127_95), "+\(pp127) % \(pp95) +\(aro127_95)")
test.eq(-Int128(pp127) / +Int128(pp95), -Int128(aqo127_95), "-\(pp127) / \(pp95) -\(aqo127_95)")
test.eq(-Int128(pp127) % +Int128(pp95), -Int128(aro127_95), "-\(pp127) % \(pp95) +\(aro127_95)")
test.eq(-Int128(pp127) / -Int128(pp95), +Int128(aqo127_95), "-\(pp127) / \(pp95) +\(aqo127_95)")
test.eq(-Int128(pp127) % -Int128(pp95), -Int128(aro127_95), "-\(pp127) % \(pp95) -\(aro127_95)")
// check generics
protocol Integer: IntegerArithmeticType, SignedIntegerType {
    init(_:Self)
}
extension Int: Integer {}
extension Int128: Integer {}
func genericSum<N:Integer>(b:N, _ e:N)->N {
    if b > e { return genericSum(e, b) }
    return (b...e).reduce(N(0), combine:+)
    
}
func genericProduct<N:Integer>(b:N, _ e:N)->N {
    if b > e { return genericProduct(e, b) }
    return (b...e).reduce(N(1), combine:*)

}
test.eq(Int128(genericSum(1,100)), genericSum(Int128(1),Int128(100)),
        "Int128(genericSum(1,100)) == genericSum(Int128(1),Int128(100))")
test.eq(Int128(genericProduct(1,16)), genericProduct(Int128(1),Int128(16)),
        "Int128(genericProduct(1,16)) == genericProduct(Int128(1),Int128(16))")
({
    func P(start:Int128, _ end:Int128)->Int128 {
        return genericProduct(start,end)
    }
    func F(n:Int128)->Int128 {
        return n < 2 ? 1 : (2...n).reduce(1,combine:*)
    }
    for i in 1...16 {
        let (b, e) = (Int128(i), Int128(i*2))
        test.eq(F(e)/F(b), P(b+1,e),"\(e)!/\(b)! == \(b+1)P\(e)")
    }
})()
// check if they are correctly arithmetic-shifting
test.eq(Int128(-1)<<1, Int128(-2), "Int128(-1)<<1 == Int128(-2)")
test.eq(Int128(-2)>>1, Int128(-1), "Int128(-2)>>1 == Int128(-1)")
//
print("#### UInt128")
debugPrint(Float128(1.0))
debugPrint(Float128(-2.0))
debugPrint(Float128(1.0/3.0))



test.done()