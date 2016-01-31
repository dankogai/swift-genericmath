//
//  util.swift
//  genericmath
//
//  Created by Dan Kogai on 2/1/16.
//  Copyright © 2016 Dan Kogai. All rights reserved.
//

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
