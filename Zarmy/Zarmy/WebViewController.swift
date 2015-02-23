//
//  WebViewController.swift
//  Zarmy
//
//  Created by Christophe Maximin on 09/02/2015.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

import CoreLocation

class WebViewController: GAITrackedViewController, UIAlertViewDelegate, UIWebViewDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate, OSKActivityCustomizations {
  
  var webView: UIWebView!
  var webViewProgressHUD: MBProgressHUD!
  var webData: NSMutableData!
  
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
    
    // AUTH
    let loginString = NSString(format: "%@:%@", UserDefaultsManager.email!, UserDefaultsManager.password!)
    let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
    let base64LoginString = loginData.base64EncodedStringWithOptions(nil)
    request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
    
    // INFO
    request.setValue("true", forHTTPHeaderField: "X-Client-WebView")
    
    webData = NSMutableData()
    NSURLConnection(request: request, delegate: self, startImmediately: true)
  }
  
  
  // MARK: UIWebView Delegate Methods
  
  func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {

    if request.URL.scheme == "zarmy-native" {

      if request.URL.host == nil {
        NSLog("Empty native action for URL: %@", request.URL)
        return false
      }
      
      let getParams = request.GETParameters() as? [String: String]
      
      switch request.URL.host! {
      case "share-message":
        if getParams?["message"] != nil {
          shareMessage(getParams!["message"]!)
        }
      case "logout":
        confirmLogOut()
      default:
        NSLog("Unknown native action for URL: %@", request.URL)
      }
      return false
    }
    
    return true
    
  }
  
  func webViewDidStartLoad(webView: UIWebView) {
    if webView.request != nil {
      showPageLoadingHUD(webView.request!)
    }
  }
  
  func webViewDidFinishLoad(webView: UIWebView) {
    hidePageLoadingHUD()
  }

  // MARK: NSURLConnection Delegate Methods
  
  func connection(connection: NSURLConnection, willSendRequest request: NSURLRequest, redirectResponse response: NSURLResponse?) -> NSURLRequest? {
    showPageLoadingHUD(request)
    return request
  }
  
  
  func connection(connection: NSURLConnection, didReceiveData data: NSData) {
    webData.appendData(data)
  }
  
  func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {

    let httpResponse = response as NSHTTPURLResponse
    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
      UserDefaultsManager.logOut()
      navigationController!.popViewControllerAnimated(true)
    } else {
      webView.loadData(webData, MIMEType: "text/html", textEncodingName: "UTF-8", baseURL: response.URL)
    }
    
    hidePageLoadingHUD()
    
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
  
  // MARK: - Helpers
  
  // Loading HUD
  
  func showPageLoadingHUD(request: NSURLRequest) {
    
    hidePageLoadingHUD()
    
    if request.URL.host == AppConfiguration.serverHost {
      webViewProgressHUD = MBProgressHUD.showHUDAddedTo(view, animated: true)
      webViewProgressHUD.labelText = "Loading..."
      webViewProgressHUD.dimBackground = true
      webViewProgressHUD.removeFromSuperViewOnHide = true
    }
  }
  
  func hidePageLoadingHUD(){
    webViewProgressHUD?.hide(true)
  }
  
  // Sharing
  
  func shareMessage(message: String) {
    
    let activitiesManager = OSKActivitiesManager.sharedInstance()
    
    activitiesManager.customizationsDelegate = self
    
    activitiesManager.markActivityTypes([OSKActivityType_iOS_ReadingList, OSKActivityType_iOS_CopyToPasteboard, OSKActivityType_iOS_Safari, OSKActivityType_iOS_SaveToCameraRoll, OSKActivityType_SDK_Pocket, OSKActivityType_URLScheme_Chrome, OSKActivityType_URLScheme_Drafts, OSKActivityType_URLScheme_Instagram, OSKActivityType_URLScheme_Omnifocus, OSKActivityType_URLScheme_Riposte, OSKActivityType_URLScheme_Things, OSKActivityType_iOS_AirDrop, OSKActivityType_API_Readability, OSKActivityType_API_Pocket, OSKActivityType_API_Pinboard, OSKActivityType_API_Instapaper, OSKActivityType_API_AppDotNet, OSKActivityType_API_500Pixels, OSKActivityType_API_GooglePlus], alwaysExcluded: true)
    
    let share = OSKShareableContent(fromText: message)
    let presManager = OSKPresentationManager.sharedInstance()
    
    presManager.presentActivitySheetForContent(share, presentingViewController: self, options: nil)
  }
  
  func applicationCredentialForActivityType(activityType: String!) -> OSKApplicationCredential! {
    
    if activityType == OSKActivityType_iOS_Facebook {
      return OSKApplicationCredential(overshareApplicationKey: "717974991663888", applicationSecret: nil, appName: "Facebook")
    }
    
    return OSKApplicationCredential()
  }
  
  // MARK: - Enums
  
  enum AlertTags: Int {
    case LoggingOut
  }
  
}