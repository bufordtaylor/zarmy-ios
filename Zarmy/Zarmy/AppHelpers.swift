//
//  AppHelpers.swift
//  Crumpets
//
//  Created by Christophe Maximin on 08/02/2015.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

class AppHelpers {
    
  // MARK: - Layout related calculations
  
  class func widthForText(text: String, font: UIFont, width: CGFloat) -> CGFloat {
    let label = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
    label.numberOfLines = 0
    label.lineBreakMode = NSLineBreakMode.ByWordWrapping
    label.font = font
    label.text = text
        
    label.sizeToFit()
    return label.frame.width
  }
  
  class func heightForText(text: String, font: UIFont, width: CGFloat) -> CGFloat {
    let label = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
    label.numberOfLines = 0
    label.lineBreakMode = NSLineBreakMode.ByWordWrapping
    label.font = font
    label.text = text
    
    label.sizeToFit()
    return label.frame.height
  }
  
//  // MARK: - Remote images
//  
//  class func applyImageURLToImageView(url: String?, imageView: UIImageView, placeholderImage: UIImage?) {
//    
//    imageView.image = placeholderImage
//    
//    if url != nil {
//      let validNSURL = NSURL(string: url!)
//      if validNSURL != nil {
//        imageView.sd_setImageWithURL(validNSURL!, placeholderImage: placeholderImage)
//      }
//    }
//  }
  
  // Google Analytics
  
  class func GA(category: String, action: String, label: String, value: NSNumber?) {
    GAI.sharedInstance().defaultTracker.send(
      GAIDictionaryBuilder.createEventWithCategory(
        category,
        action: action,
        label: label,
        value: value).build())
  }
  
  // iOS Versions
  
  class func iOSVersion() -> Double {
    return (UIDevice.currentDevice().systemVersion as NSString).doubleValue
  }
  
  // Push Notification
  
  class func dataToHex(data: NSData) -> NSString {
    var str = NSMutableString(capacity: 100)
    let p = UnsafePointer<UInt8>(data.bytes)
    let len = data.length
    
    for var i=0; i<len; ++i {
      str.appendFormat("%02.2X", p[i])
    }
    
    return str
  }

  class func askForPushNotificationRights() {
    UserDefaultsManager.askedForPushNotificationRights = true

    if AppHelpers.iOSVersion() >= 8 {
      let settings = UIUserNotificationSettings(forTypes: .Alert | .Sound | .Badge, categories: nil)
      UIApplication.sharedApplication().registerUserNotificationSettings(settings)
      UIApplication.sharedApplication().registerForRemoteNotifications()
    } else {
      UIApplication.sharedApplication().registerForRemoteNotificationTypes(.Alert | .Badge | .Sound)
    }
  }

}