//
//  APIClientManager.swift
//  Crumpets
//
//  Created by Christophe Maximin on 08/02/2015.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

import CoreData

class APIClientManager: AFHTTPRequestOperationManager {
  var responseCameFromCache = true // Inspired by http://stackoverflow.com/a/21556002
  var beforeImportingEntities: (() -> Void)? = nil

  class var sharedInstance: APIClientManager {
    return APIClientManagerSharedInstance
  }
  
  init() {
    let apiURL = AppConfiguration.serverBaseURLViaSSL + "/api/v\(AppConfiguration.apiVersion)"
    
    super.init(baseURL: NSURL(string: apiURL))

    
    requestSerializer.timeoutInterval = 20
  }
  
  
  // MARK: - API calls
  
  func apiGET(path: String!, var params: [String: AnyObject]?, success: APIRequestCustomSuccessBlock?, failure: APIRequestCustomFailureBlock?, alertWhenUnreachable: Bool = true) {
    
    NSLog("APIClientManager: apiGET() request to path '\(path)', params: '\(params)' ")
    
    if preRequestReachabilityCheck(alertWhenUnreachable) {
      
      params = setAppVersion(params)
      
      let operation = GET(
        path,
        parameters: params,
        success: apiRequestStandardSuccess(success),
        failure: apiRequestStandardFailure(failure)
      )
      
      responseCameFromCache = true
      // This will be called whenever server returns status code 200, not 304
      operation.setCacheResponseBlock { (connection: NSURLConnection!, cachedResponse: NSCachedURLResponse!) -> NSCachedURLResponse! in
        self.responseCameFromCache = false
        return cachedResponse
      }
      
    } else {
      failure?(responseObject: nil, error: nil)
    }
    
  }
  
  func apiPOST(path: String!, var params: [String: AnyObject]?, success: APIRequestCustomSuccessBlock?, failure: APIRequestCustomFailureBlock?, alertWhenUnreachable: Bool = true) {
    
    NSLog("APIClientManager: apiPOST() request to path '\(path)', params: '\(params)' ")
    
    if preRequestReachabilityCheck(alertWhenUnreachable) {
      
      params = setAppVersion(params)
      
      POST(
        path,
        parameters: params,
        success: apiRequestStandardSuccess(success),
        failure: apiRequestStandardFailure(failure)
      )
      
    } else {
      failure?(responseObject: nil, error: nil)
    }
  }
  
  // MARK: API calls - Users
  
  func createUser(params: [String: AnyObject], success: APIRequestCustomSuccessBlock?, failure: APIRequestCustomFailureBlock?) {
    
    apiPOST(
      "users",
      params: params,
      success: { (responseObject, importedObjects) in
        
        let userObject = responseObject["user"] as [String: AnyObject]
        
        UserDefaultsManager.logIn(
          userObject["email"] as String,
          password: params["user"]!["password"] as String
        )
        
        self.saveUserDataFromResponse(userObject)
        
        success?(responseObject: responseObject, importedObjects: importedObjects)
        
      },
      failure: failure
    )
  }
  
  func createSession(params: [String: AnyObject], success: APIRequestCustomSuccessBlock?, failure: APIRequestCustomFailureBlock?) {
    
    apiPOST(
      "sessions",
      params: params,
      success: { (responseObject, importedObjects) in
        
        let userObject = responseObject["user"] as [String: AnyObject]
        
        UserDefaultsManager.logIn(
          userObject["email"] as String,
          password: params["password"] as String
        )
        
        self.saveUserDataFromResponse(userObject)
        
        success?(responseObject: responseObject, importedObjects: importedObjects)
        
      },
      failure: failure
    )
  }

  
//  func resetPassword(email: String, success: APIRequestCustomSuccessBlock?, failure: APIRequestCustomFailureBlock?) {
//    
//    var params = [String: AnyObject]()
//    params["email"] = email
//    
//    apiPOST(
//      "users/change_password",
//      params: params,
//      success: success,
//      failure: failure
//    )
//  }
  
  func getCurrentUser(success: APIRequestCustomSuccessBlock? = nil, failure: APIRequestCustomFailureBlock? = nil) {
    
    setAuthCurrentUser()
    
    apiGET(
      "users/show",
      params: nil,
      success: { (responseObject, importedObjects) in
        
        self.saveUserDataFromResponse(responseObject["user"] as [String: AnyObject])
        
        if success != nil {
          success!(responseObject: responseObject, importedObjects: importedObjects)
        }

      },
      failure: failure
    )
  
  }
  
  func postAPNToken(token: String, success: APIRequestCustomSuccessBlock? = nil, failure: APIRequestCustomFailureBlock? = nil) {
    
    if UserDefaultsManager.loggedIn {
      setAuthCurrentUser()
    }
    
    apiPOST(
      "users/notification_token",
      params: [
        "token": token
      ],
      success: { (responseObject, importedObjects) in
        
        UserDefaultsManager.serverReceivedPushNotificationToken = true
        
        if success != nil {
          success!(responseObject: responseObject, importedObjects: importedObjects)
        }
        
      },
      failure: failure
    )
    
  }
  
  // MARK: - Helpers
  
  func apiRequestStandardSuccess(successBlock: APIRequestCustomSuccessBlock?) -> (AFHTTPRequestOperation!, AnyObject!) -> Void {
    
    return {
      (operation: AFHTTPRequestOperation!, possibleResponseObject: AnyObject!) in
//      NSLog("APIClientManager: apiRequestStandardSuccess() \n\(operation)\n\(responseObject)")
      NSLog("APIClientManager: apiRequestStandardSuccess()")
      
      if let responseObject = possibleResponseObject as? [String: AnyObject] {
        
        self.beforeImportingEntities?()
        let importedObjects = self.importObjectsToDatabase(responseObject)
        self.beforeImportingEntities = nil
        
        if successBlock != nil {
          successBlock!(responseObject: responseObject, importedObjects: importedObjects)
        }
        
      } else {
        
        if successBlock != nil {
          successBlock!(responseObject: [String: AnyObject](), importedObjects: [])
        }
        
      }
      
//      CoreDataManager.saveMainContext()
    }
  }
  
  
  func apiRequestStandardFailure(failureBlock: APIRequestCustomFailureBlock?) -> (AFHTTPRequestOperation!, NSError!) -> Void {
    
    return {
      (operation: AFHTTPRequestOperation!, error: NSError!) in
      NSLog("APIClientManager: apiRequestStandardFailure()")
      if operation != nil { NSLog("%@", operation) }
      if error != nil { NSLog("%@", error) }
      
      if operation.response?.statusCode >= 500 {
        // NOTE: if you don't want to show an alert for some actions,
        // like because you want the UI to be updated nicely instead of a brutal alert, you'll need to create an instance variable
        // like "alertOnUnmanagedErrors" that gets resetted after the failure block is executed

        UIAlertView(title: "This is embarrassing...", message: "You've found a bug in our system. We've got robots sending the error analysis to our engineers, who we hooked to coffee IVs. We've also alerted the president.", delegate: nil, cancelButtonTitle: "Cancel").show()
        AppHelpers.GA("soft_error", action: "api_client", label: error.localizedDescription, value: nil)
        
      } else if operation.response == nil && error != nil {
        
        let errorDetails = error.localizedDescription + "\n\(error.userInfo)"
        UIAlertView(title: "Error", message: errorDetails, delegate: nil, cancelButtonTitle: "Cancel").show()
        AppHelpers.GA("unmanaged_error", action: "api_client", label: errorDetails, value: nil)
      }
      
      if failureBlock != nil {
        failureBlock!(responseObject: operation.responseObject as? [String: AnyObject], error: error)
      }
    }
  }
  
  
  func importObjectsToDatabase(dictionary: [String: AnyObject]) -> [NSManagedObject] {
    
    var allImportedObjects = [NSManagedObject]()
//    let localContext = CoreDataManager.sharedInstance.mainContext
//    
//    for (key, object) in dictionary {
//      var localEntityName = ServerJSONKeysToLocalEntities[key as String]
//      var justImportedObjects: [NSManagedObject] = []
//      
//      if localEntityName != nil {
//        var managedObjectClass = NSClassFromString(localEntityName) as NSManagedObject.Type
//        
//        if object as? NSDictionary != nil {
//          justImportedObjects = [managedObjectClass.MR_importFromObject(object as [String: AnyObject], inContext: localContext)]
//        } else if object as? NSArray != nil {
//          justImportedObjects = managedObjectClass.MR_importFromArray(object as [[String: AnyObject]], inContext: localContext) as [NSManagedObject]
//        }
//      }
//      
//      for importedObject in justImportedObjects {
//        allImportedObjects.append(importedObject)
//      }
//      
//    }
    
    return allImportedObjects
  }
  
  func setAuthCurrentUser() {
    requestSerializer.clearAuthorizationHeader()
    requestSerializer.setAuthorizationHeaderFieldWithUsername(UserDefaultsManager.email!, password: UserDefaultsManager.password!)
  }
  
  func setAppVersion(var params: [String: AnyObject]?) -> [String: AnyObject] {
    let bundleVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as String
    let bundleShortVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as String
    let version = "\(bundleVersion)-\(bundleShortVersion)"

    if params == nil {
      params = [String: AnyObject]()
    }
    
    params!["version"] = version
    
    return params!
  }
  
  func preRequestReachabilityCheck(alertWhenUnreachable: Bool) -> Bool {
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    if alertWhenUnreachable && !appDelegate.currentlyReachable {
      UIAlertView(title: "No Internets", message: "We could not connect you. Are you sure you're online?", delegate: nil, cancelButtonTitle: "Try again").show()
      AppHelpers.GA("soft_error", action: "api_client", label: "unreachable", value: nil)
    }
    
    return appDelegate.currentlyReachable
  }
  
  func saveUserDataFromResponse(userObject: [String: AnyObject]) {
    
    UserDefaultsManager.name = userObject["name"] as? String
    
  }

//  // MARK: - Core Data
//  lazy var coreDataManager: CoreDataManager = {
//    return CoreDataManager.sharedInstance
//  }()
  
  // MARK: - NSCoding Protocol
  
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}

private let APIClientManagerSharedInstance = APIClientManager()
typealias APIRequestCustomSuccessBlock = (responseObject: [String: AnyObject], importedObjects: [NSManagedObject]) -> Void
typealias APIRequestCustomFailureBlock = (responseObject: [String: AnyObject]?, error: NSError?) -> Void
//let ServerJSONKeysToLocalEntities:[String: String] = [
//  "events": "Crumpets.Event",
//]
