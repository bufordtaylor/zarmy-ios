//
//  String+rangeSubscript.swift
//  Crumpets
//
//  Created by Christophe Maximin on 08/02/2015.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

extension String {
  subscript(integerIndex: Int) -> Character {
    let index = advance(startIndex, integerIndex)
    return self[index]
  }
  
  subscript(integerRange: Range<Int>) -> String {
    let start = advance(startIndex, integerRange.startIndex)
    let end = advance(startIndex, integerRange.endIndex)
    let range = start..<end
    return self[range]
  }
}
