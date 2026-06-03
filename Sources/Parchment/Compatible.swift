//
//  Compatible.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

/// CompatibleWrapper<Base>
struct CompatibleWrapper<Base> {
    internal var base: Base
    internal init(_ base: Base) {
        self.base = base
    }
}

/// Compatible
protocol Compatible: AnyObject {}
extension Compatible {
 
    /// CompatibleWrapper<Self>
    internal var hub: CompatibleWrapper<Self> {
        get { CompatibleWrapper(self) }
        set { }
    }
}

/// CompatibleValue
protocol CompatibleValue {}
extension CompatibleValue {
    
    /// CompatibleWrapper<Self>
    internal var hub: CompatibleWrapper<Self> {
        get { CompatibleWrapper(self) }
        set { }
    }
}
