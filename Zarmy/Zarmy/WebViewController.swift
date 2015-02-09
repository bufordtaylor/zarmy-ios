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
  }
  
  // MARK: - Enums
  
  enum AlertTags: Int {
    case LoginWithEmail
  }
  
}