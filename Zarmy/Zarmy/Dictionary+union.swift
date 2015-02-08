//
//  Dictionary.swift
//  Crumpets
//
//  Created by Christophe Maximin on 08/02/2015.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

internal extension Dictionary {
  
  func union (dictionaries: Dictionary...) -> Dictionary {
    
    var result = self
    
    for dictionary in dictionaries {
      for (key, value) in dictionary {
        result.updateValue(value, forKey: key)
      }
    }
    
    return result
  }
}