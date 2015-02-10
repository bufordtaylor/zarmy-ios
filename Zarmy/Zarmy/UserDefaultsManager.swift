//
//  UserDefaultsManager.swift
//  Crumpets
//
//  Created by Christophe Maximin on 08/02/2015.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

class UserDefaultsManager {
  
  class var SUD: NSUserDefaults {
    return NSUserDefaults.standardUserDefaults()
  }
  
  // MARK: - Helpers
  
  class func logIn(email: String, password: String) {
    self.loggedIn = true
    self.email = email
    self.password = password
  }
  
  class func logOut() {
    self.loggedIn = false
    self.password = nil
    FBSession.activeSession().closeAndClearTokenInformation()
    self.name = ""
  }
  
  // MARK: - Accessors
  
  class var loggedIn: Bool {
    get { return SUD.boolForKey("logged_in") }
    set { return SUD.setBool(newValue, forKey: "logged_in") }
  }

  class var email: String? {
    get { return SUD.stringForKey("email") }
    set { return SUD.setObject(newValue, forKey: "email") }
  }
  
  class var password: String? {
    get { return SUD.stringForKey("password") }
    set { return SUD.setObject(newValue, forKey: "password") }
  }
  
  class var name: String? {
    get { return SUD.stringForKey("name") }
    set { return SUD.setObject(newValue, forKey: "name") }
  }
  
  class var askedForPushNotificationRights: Bool {
    get { return SUD.boolForKey("asked_for_push_notification_rights") }
    set { return SUD.setBool(newValue, forKey: "asked_for_push_notification_rights") }
  }
  
  class var serverReceivedPushNotificationToken: Bool {
    get { return SUD.boolForKey("server_received_push_notification_token") }
    set { return SUD.setBool(newValue, forKey: "server_received_push_notification_token") }
  }

  class var pushNotificationToken: String? {
    get { return SUD.stringForKey("push_notification_token") }
    set { return SUD.setObject(newValue, forKey: "push_notification_token") }
  }


}