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
  
  class var serverBaseURL: String {
    return productionEnvironment ? "http://zarmy.club" : "http://zarmy.dev"
  }
  
  class var serverBaseURLViaSSL: String {
    return productionEnvironment ? "https://zarmy.club" : "http://zarmy.dev"
  }
  
  class var apiVersion: Int {
    return 1
  }
  
  // MARK: - Google Analytics
  class var googleAnalyticsTrackingID: String {
    return productionEnvironment ? "UA-PRODXXX" : "DEV"
  }
  
  // MARK: - Mixpanel
  class var mixpanelToken: String {
    return productionEnvironment ? "PRODXXX" : "DEV"
  }
  
  
  // MARK: - UI
  
  class var mainColor: [String: UIColor] {
    return [
      "green": UIColor(hexRGB: "50c185"),
    ]
  }
}
