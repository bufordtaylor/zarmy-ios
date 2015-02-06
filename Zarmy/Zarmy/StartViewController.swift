//
//  StartViewController.swift
//  Zarmy
//
//  Created by Adam Clarke on 06/02/2015.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {
  
  @IBOutlet var facebookButton: UIButton!
  @IBOutlet var loginButton: UIButton!
  @IBOutlet var signupButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    facebookButton.layer.cornerRadius = 3
    facebookButton.backgroundColor = UIColor(red: 59.0/255.0, green: 89.0/255.0, blue: 152.0/255.0, alpha: 1.0)

    
  }
}