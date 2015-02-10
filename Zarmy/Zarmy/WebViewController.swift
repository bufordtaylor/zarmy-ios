//
//  WebViewController.swift
//  Zarmy
//
//  Created by Christophe Maximin on 09/02/2015.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

import CoreLocation

class WebViewController: GAITrackedViewController, UIAlertViewDelegate, UIWebViewDelegate, NSURLConnectionDelegate {
  
  var webView: UIWebView!
  var requestsCount: Int = 0
  var webViewProgressHUD: MBProgressHUD!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if !UserDefaultsManager.loggedIn {
      NSLog("Error: The user should be logged in to access the webView")
      navigationController!.popViewControllerAnimated(true)
      return
    }
    
    if UserDefaultsManager.pushNotificationToken != nil && !UserDefaultsManager.serverReceivedPushNotificationToken {
      APIClientManager.sharedInstance.postAPNToken(UserDefaultsManager.pushNotificationToken!)
    }
    
    webView = UIWebView()
    webView.frame = view.frame
    webView.delegate = self
    view.addSubview(webView)
    
    let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
    hud.labelText = "Getting your location..."
    hud.dimBackground = true
    hud.removeFromSuperViewOnHide = true
    
    INTULocationManager.sharedInstance().requestLocationWithDesiredAccuracy(
      .Neighborhood,
      timeout: 10,
      delayUntilAuthorized: true,
      block: {
        (currentLocation: CLLocation!, achievedAccuracy: INTULocationAccuracy, status: INTULocationStatus) in
        
        if status == .Success {
          let coordinate = currentLocation.coordinate
          self.loadWebView(addingToURL: "?latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)")
        } else {
          self.loadWebView()
        }
        
        hud.hide(true)
      }
    )
    
    
    let logoutGesture = UITapGestureRecognizer(target: self, action: "confirmLogOut")
    logoutGesture.numberOfTapsRequired = 5
    webView.addGestureRecognizer(logoutGesture)
  }
  
  override func viewWillAppear(animated: Bool) {
    
    let statusBar = UIView(frame: CGRectMake(0, 0, view.frame.size.width, 20))
    statusBar.backgroundColor = UIColor(hexRGB: "28C9B6")
    view.addSubview(statusBar)
    
    webView.backgroundColor = UIColor(hexRGB: "28C9B6")
    
    var viewBounds = webView.bounds
    viewBounds.origin.y = -20
    viewBounds.size.height = viewBounds.size.height + 20
    view.frame = viewBounds
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
  
  func loadWebView(addingToURL: String = "") {
    var urlPath = AppConfiguration.serverBaseURLViaSSL + "/webflow" + addingToURL
    let url = NSURL(string: urlPath)!
    let request = NSMutableURLRequest(URL: url)
    
    let loginString = NSString(format: "%@:%@", UserDefaultsManager.email!, UserDefaultsManager.password!)
    let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
    let base64LoginString = loginData.base64EncodedStringWithOptions(nil)
    request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
    
    if requestsCount == 0 {
      webViewProgressHUD = MBProgressHUD.showHUDAddedTo(view, animated: true)
      webViewProgressHUD.labelText = "Loading activities..."
      webViewProgressHUD.dimBackground = true
      webViewProgressHUD.removeFromSuperViewOnHide = true
    }

    webView.loadRequest(request)
  }
  
  // MARK: UIWebView Delegate Methods
  
  func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
    let connection = NSURLConnection(request: request, delegate: self)
    return connection != nil
  }
  
  func webViewDidStartLoad(webView: UIWebView) {
  }
  
  func webViewDidFinishLoad(webView: UIWebView) {
    if requestsCount == 0 {
      webViewProgressHUD.hide(true)
    }
    
    requestsCount += 1
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