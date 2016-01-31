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

}