//
//  WebViewController.swift
//  Zarmy
//
//  Created by Christophe Maximin on 09/02/2015.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

class WebViewController: GAITrackedViewController, UIAlertViewDelegate, UIWebViewDelegate, NSURLConnectionDelegate {
  
  var webView: UIWebView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if !UserDefaultsManager.loggedIn {
      NSLog("Error: The user should be logged in to access the webView")
      navigationController!.popViewControllerAnimated(true)
      return
    }

    let urlPath = AppConfiguration.serverBaseURLViaSSL + "/webflow"
    let url = NSURL(string: urlPath)!
    let request = NSMutableURLRequest(URL: url)
    
    let loginString = NSString(format: "%@:%@", UserDefaultsManager.email!, UserDefaultsManager.password!)
    let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
    let base64LoginString = loginData.base64EncodedStringWithOptions(nil)
    request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
    
    webView = UIWebView()
    webView.frame = view.frame
    webView.loadRequest(request)
    webView.delegate = self
    
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
  
  // MARK: UIWebView Delegate Methods
  
  func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
    let connection = NSURLConnection(request: request, delegate: self)
    return connection != nil
  }
  
  // MARK: NSURLConnection Delegate Methods
  
  func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
    let httpResponse = response as NSHTTPURLResponse
    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
      UserDefaultsManager.logOut()
      navigationController!.popViewControllerAnimated(true)
    }

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