//
//  WebViewController.swift
//  Zarmy
//
//  Created by Christophe Maximin on 09/02/2015.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

class WebViewController: GAITrackedViewController, UIAlertViewDelegate, UIWebViewDelegate {
  
  var webView: UIWebView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    webView = UIWebView()
    webView.frame = view.frame
    
    let url = AppConfiguration.serverBaseURLViaSSL + "/webflow"
    webView.loadRequest(NSURLRequest(URL: NSURL(string: url)!))
    
    view.addSubview(webView)
    
    let logoutGesture = UITapGestureRecognizer(target: self, action: "confirmLogOut")
    logoutGesture.numberOfTapsRequired = 5
    webView.addGestureRecognizer(logoutGesture)
  }
  
  func confirmLogOut() {
    let alert = UIAlertView(title: "Log out?",
      message: "You are currently logged in as \(UserDefaultsManager.email!)",
      delegate: self,
      cancelButtonTitle: "Cancel",
      otherButtonTitles: "Log out")
    
    alert.tag = AlertTags.LoggingOut.rawValue
    alert.show()
  }
  
  // MARK: - UIAlertView Delegate Methods
  
  func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
    
    if buttonIndex == 0 { // cancel
      return
    }
    
    switch AlertTags(rawValue: alertView.tag)! {
      
    case .LoggingOut:
      if buttonIndex == 1 { // Log out
        UserDefaultsManager.logOut()
        navigationController!.popViewControllerAnimated(true)
      }
      
    } // switch AlertTags
  }

  
  // MARK: - Enums
  
  enum AlertTags: Int {
    case LoggingOut
  }
  
}