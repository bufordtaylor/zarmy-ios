//
//  UIView+initWithNib.swift
//  Crumpets
//
//  Created by Adam Clarke on 14/10/2014.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

import UIKit

extension UIView {
  class func loadFromNibNamed(nibNamed: String, bundle: NSBundle? = nil) -> UIView? {
    let nib = UINib(nibName: nibNamed, bundle: bundle)
    let view = nib.instantiateWithOwner(nil, options: nil)[0] as? UIView
    return view
  }
}
