//
//  UIColor+hexRGB.swift
//  Crumpets
//
//  Created by Christophe Maximin on 08/02/2015.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

import UIKit

extension UIColor {
  
  // Init with a number and alpha, e.g. UIColor(intHexRGB: 0xFF0000, alpha: 0.6)
  convenience init(intHexRGB: UInt32, alpha: CGFloat) {
    self.init(
      red: CGFloat( CGFloat((intHexRGB & 0xFF0000) >> 16) / 255 ),
      green: CGFloat( CGFloat((intHexRGB & 0xFF00) >> 8) / 255 ),
      blue: CGFloat( CGFloat(intHexRGB & 0xFF) / 255 ),
      alpha: alpha
    )
  }
  
  // Init with a number, e.g. UIColor(intHexRGB: 0xFF0000)
  convenience init(intHexRGB: UInt32) {
    self.init(
      intHexRGB: intHexRGB,
      alpha: 1
    )
  }
  
  // Init with a string and alpha e.g. UIColor(hexRGB: "FF0000", alpha: 0.6)
  convenience init(hexRGB: String, alpha: CGFloat) {
    self.init(
      intHexRGB: UInt32(UIColor.hexToInt(hexRGB as String)),
      alpha: alpha
    )
  }
  
  // Init with a string e.g. UIColor(hexRGB: "FF0000")
  convenience init(hexRGB: String) {
    self.init(
      intHexRGB: UInt32(UIColor.hexToInt(hexRGB)),
      alpha: 1
    )
  }
  
  
  // MARK: - Internal helpers
  
  class func hexToInt(hex: String) -> UInt32 {
    var result: UInt32 = 0
    NSScanner(string: hex).scanHexInt(&result)
    
    return result
  }
}