//
//  AppConfiguration.swift
//  Crumpets
//
//  Created by Christophe Maximin on 08/02/2015.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

class AppConfiguration {
  
  class var environment: String {
    // comment one or the other return line if you want to run in development or production
    
//    return "development"
    return "production"
  }
  
  // MARK: - Environment shorthands
  
  class var productionEnvironment: Bool {
    return environment == "production"
  }
  
  class var developmentEnvironment: Bool {
    return !productionEnvironment
  }
  
  // MARK: - Server URLs & API
  
  class var serverHost: String {
    return productionEnvironment ? "zarmy.club" : "zarmy.dev"
  }

  class var serverBaseURL: String {
    return "http://\(serverHost)"
  }
  
  class var serverBaseURLViaSSL: String {
    // TODO: get SSL certificate
//    return "https://\(serverHost)"
    return "http://\(serverHost)"
  }
  
  class var apiVersion: Int {
    return 1
  }
  
  
  // MARK: - UI
  
  class var mainColor: [String: UIColor] {
    return [
      "green": UIColor(hexRGB: "50c185"),
    ]
  }
}
