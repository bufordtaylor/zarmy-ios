//
//  StartViewController.swift
//  Zarmy
//
//  Created by Adam Clarke on 06/02/2015.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

class StartViewController: GAITrackedViewController, UIAlertViewDelegate {
  
  @IBOutlet var facebookButton: UIButton!
  @IBOutlet var loginButton: UIButton!
  @IBOutlet var signupButton: UIButton!
  @IBOutlet var toddlerWidth: NSLayoutConstraint!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    facebookButton.layer.cornerRadius = 5
    facebookButton.backgroundColor = UIColor(red: 59.0/255.0, green: 89.0/255.0, blue: 152.0/255.0, alpha: 1.0)
  
  }
  
  override func viewWillAppear(animated: Bool) {
    if view.frame.size.width < 350 {
      toddlerWidth.constant = 120
    }
  }
  
  // MARK: - IBActions
  
  @IBAction func emailLoginTapped(sender: UIButton) {
    showLoginAlert("Login", message: "Please enter your email and password")
  }
  
  @IBAction func emailSignupTapped(sender: UIButton) {
    showSignupAlert("Signup", message: "Please enter your email and create a password")
  }
  
  @IBAction func facebookLoginTapped(sender: UIButton) {
    FBSession.activeSession().closeAndClearTokenInformation()
    
    let readPermissions = ["public_profile", "email", "user_friends", "user_checkins", "friends_checkins", "user_photos"]
    
    let session = FBSession(permissions: readPermissions)
    FBSession.setActiveSession(session)
    
    let correctlyLoggedInAction = { (session: FBSession) -> Void in
      FBRequest.requestForMe().startWithCompletionHandler {
        (connection: FBRequestConnection!, user: AnyObject!, error: NSError!) in
        
        let userDict = user as [String: AnyObject]
        let accessToken = session.accessTokenData.accessToken
        let password = (accessToken as NSString).substringToIndex(32)
        let email = userDict["email"] as String
        
        let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        hud.labelText = "Logging in..."
        hud.dimBackground = true
        hud.removeFromSuperViewOnHide = true
        
        APIClientManager.sharedInstance.createUser(
          [
            "user": [
              "email": email,
              "password": password,
              "facebook_access_token": accessToken
            ],
            "login_if_registered": "1"
          ],
          success: { (responseObject, importedObjects) in
            hud.hide(true)
            
            self.navigationController!.pushViewController(WebViewController(), animated: true)
          },
          failure: { (responseObject, error) in
            hud.hide(false)
            
            session.closeAndClearTokenInformation()
            
            if let reasons = responseObject?["reasons"] as? [String] {
              self.showLoginAlert("Error while logging in",
                message: "\n-> " + "\n-> ".join(reasons) + "\n\nPlease try again.",
                email: email)
            }
          }
        ) // APIClientManager.sharedInstance.createUser
        
      } // FBRequest.requestForMe().startWithCompletionHandler
      
      return
    } // correctlyLoggedInAction
    
    
    session.openWithBehavior(.WithFallbackToWebView) {
      (session: FBSession!, status: FBSessionState, error: NSError!) in
      
      if error != nil {
        AppHelpers.GA("soft_error", action: "facebook-login", label: error.localizedDescription, value: nil)
        NSLog("Error: Could not open Facebook session \(error)")
        return
      }
      
      if !session.isOpen {
        // it will automatically opened and the block of session.openWithBehavior will be re-executed
        return
      }
      
      if !session.hasGranted("email") {
//        UIAlertView(title: "Error while logging in",
//          message: "We need your email address to create an account on Zarmy.",
//          delegate: nil,
//          cancelButtonTitle: nil,
//          otherButtonTitles: "Try again").show()
        
        session.requestNewReadPermissions(readPermissions) {
          (session: FBSession!, error: NSError!) -> Void in
          
          if error != nil {
            AppHelpers.GA("soft_error", action: "facebook-login", label: error.localizedDescription, value: nil)
            NSLog("Error: Could not open Facebook session (2) \(error)")
            return
          }
          
          correctlyLoggedInAction(session)
        }
        return
      } // if !session.hasGranted("email")
      
      correctlyLoggedInAction(session)
      
    } // session.openWithBehavior
    
  } // facebookLoginTapped


  func showLoginAlert(title: String, message: String, email: String = "") {
    
    let alertView = UIAlertView(
      title: title,
      message: message,
      delegate: self,
      cancelButtonTitle: "Cancel",
      otherButtonTitles: "Log in")
    
    alertView.alertViewStyle = .LoginAndPasswordInput
    alertView.tag = AlertTags.LoginWithEmail.rawValue
    
    alertView.textFieldAtIndex(0)!.placeholder = "Email"
    alertView.textFieldAtIndex(0)!.text = email
    
    alertView.show()
  }
  
  func showSignupAlert(title: String, message: String, email: String = "") {
    
    let alertView = UIAlertView(
      title: title,
      message: message,
      delegate: self,
      cancelButtonTitle: "Cancel",
      otherButtonTitles: "Sign up")
    
    alertView.alertViewStyle = .LoginAndPasswordInput
    alertView.tag = AlertTags.SignupWithEmail.rawValue
    
    alertView.textFieldAtIndex(0)!.placeholder = "Email"
    alertView.textFieldAtIndex(0)!.text = email
    
    alertView.show()
  }

  
  // MARK: - UIAlertView Delegate Methods
  
  func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
    
    if buttonIndex == 0 { // cancel
      return
    }

    switch AlertTags(rawValue: alertView.tag)! {
      
    case .LoginWithEmail:
      let email = alertView.textFieldAtIndex(0)!.text
      let password = alertView.textFieldAtIndex(1)!.text
      
      let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
      hud.labelText = "Logging in..."
      hud.dimBackground = true
      hud.removeFromSuperViewOnHide = true
      
      APIClientManager.sharedInstance.createSession(
        [
          "email": email,
          "password": password
        ],
        success: { (responseObject, importedObjects) in
          hud.hide(true)
          
          self.navigationController!.pushViewController(WebViewController(), animated: true)
        },
        failure: { (responseObject, error) in
          hud.hide(false)
          
          if let reasons = responseObject?["reasons"] as? [String] {
            
            self.showLoginAlert("Error while logging in",
              message: "\n-> " + "\n-> ".join(reasons) + "\n\nPlease try again.",
              email: email)
            
          }
        }
      ) // APIClientManager.sharedInstance.createSession
      
    case .SignupWithEmail:
      let email = alertView.textFieldAtIndex(0)!.text
      let password = alertView.textFieldAtIndex(1)!.text
      
      let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
      hud.labelText = "Signing up..."
      hud.dimBackground = true
      hud.removeFromSuperViewOnHide = true
      
      APIClientManager.sharedInstance.createUser(
        [
          "user": [
            "email": email,
            "password": password
          ],
          "login_if_registered": "1"
        ],
        success: { (responseObject, importedObjects) in
          hud.hide(true)
          
          self.navigationController!.pushViewController(WebViewController(), animated: true)
        },
        failure: { (responseObject, error) in
          hud.hide(false)
          
          if let reasons = responseObject?["reasons"] as? [String] {
            
            self.showSignupAlert("Error while signing up",
              message: "\n-> " + "\n-> ".join(reasons) + "\n\nPlease try again.",
              email: email)
            
          }
        }
      ) // APIClientManager.sharedInstance.createUser

    } // switch AlertTags
  }


  // MARK: - Enums
  
  enum AlertTags: Int {
    case SignupWithEmail
    case LoginWithEmail
  }

}