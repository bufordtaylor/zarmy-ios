//
//  APIClientManager.swift
//  Crumpets
//
//  Created by Christophe Maximin on 08/02/2015.
//  Copyright (c) 2015 Zarmy. All rights reserved.
//

class APIClientManager: AFHTTPRequestOperationManager {
  /*
  var responseCameFromCache = true // Inspired by http://stackoverflow.com/a/21556002
  var beforeImportingEntities: (() -> Void)? = nil

  class var sharedInstance: APIClientManager {
    return APIClientManagerSharedInstance
  }
  
  override init() {
    let apiURL = AppConfiguration.serverBaseURLViaSSL + "/api"
    
    super.init(baseURL: NSURL(string: apiURL))

    requestSerializer.setValue(
      "application/vnd.shortcut.v\(AppConfiguration.apiVersion)",
      forHTTPHeaderField: "Accept"
    )
    
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
      params = setFacebookToken(params)
      
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
  
  // MARK: API calls - Events
  
  func getEvents(var params: [String: AnyObject]?, success: APIRequestCustomSuccessBlock?, failure: APIRequestCustomFailureBlock?) {
    
    var context = CoreDataManager.sharedInstance.mainContext

    // TODO: remove remove old venues/events at some point, because they're never deleted and it will eventually fill the DB
    
    // Unlisting all events before getting the new ones
    let events = Event.MR_findAllInContext(context)
    for event in events as [Event] {
      event.listed = false
      PickupTime.MR_deleteAllMatchingPredicate(NSPredicate(format: "event = %@", event), inContext: context)
    }
    
    CoreDataManager.saveMainContext()
    
    if let token = UserDefaultsManager.pushNotificationToken {
      if params == nil {
        params = [String: AnyObject]()
      }
      
      params!["push_notification_token"] = token
    }
    
    apiGET(
      "events",
      params: params,
      success: { (responseObject, importedObjects) in
        
        // Setting all imported events as being listed
        // Setting a position for all imported events
        var newPosition = 0

        for object in importedObjects {
          if object.entity.managedObjectClassName == "Crumpets.Event" {
            let event = object as Event
            event.listed = true
            event.position = newPosition
            
            newPosition = newPosition + 1
          }
        }
        
        CoreDataManager.saveMainContext()
        
        if success != nil {
          success!(responseObject: responseObject, importedObjects: importedObjects)
        }
      },
      failure: failure
    )
  }
  
  // MARK: API calls - Inventories
  
  func getInventories(event: Event, success: APIRequestCustomSuccessBlock?, failure: APIRequestCustomFailureBlock?) {

    var context = CoreDataManager.sharedInstance.mainContext
    
    beforeImportingEntities = {
      if !self.responseCameFromCache {
        Inventory.MR_deleteAllMatchingPredicate(NSPredicate(format: "event = %@", event), inContext: context)
        Tier.MR_deleteAllMatchingPredicate(NSPredicate(format: "event = %@", event), inContext: context)
        Concession.MR_deleteAllMatchingPredicate(NSPredicate(format: "event = %@", event), inContext: context)
      }
    }
    
    apiGET(
      "inventories",
      params: ["event_id": event.uid],
      success: { (responseObject: [String: AnyObject], importedObjects: [NSManagedObject]) in
        
        // Attach inventories and tiers to event
        for object in importedObjects {
          if object.entity.managedObjectClassName == "Crumpets.Inventory" {
            let inventory = object as Inventory
            inventory.event = event
          } else if object.entity.managedObjectClassName == "Crumpets.Tier" {
            let tier = object as Tier
            tier.event = event
          } else if object.entity.managedObjectClassName == "Crumpets.Concession" {
            let concession = object as Concession
            concession.event = event
          }
        }
        
        success?(responseObject: responseObject, importedObjects: importedObjects)
        
      },
      
      failure: failure
    )
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
        
        if success != nil {
          success!(responseObject: responseObject, importedObjects: importedObjects)
        }
        
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
          password: params["user"]!["password"] as String
        )
        
        self.saveUserDataFromResponse(userObject)
        
        if success != nil {
          success!(responseObject: responseObject, importedObjects: importedObjects)
        }

      },
      failure: failure
    )
  }
  
  func resetPassword(email: String, success: APIRequestCustomSuccessBlock?, failure: APIRequestCustomFailureBlock?) {
    
    var params = [String: AnyObject]()
    params["email"] = email
    
    apiPOST(
      "users/change_password",
      params: params,
      success: success,
      failure: failure
    )
  }
  
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

  // MARK: API calls - Orders

  func createOrder(cartManager: CartManager, success: APIRequestCustomSuccessBlock?, failure: APIRequestCustomFailureBlock?) {

    let cart = cartManager.cart
    
    var params = [String: AnyObject]()
    params["order"] = buildOrderParams(cart)
    
    if UserDefaultsManager.stripeToken != nil {
      params["stripe_token"] = UserDefaultsManager.stripeToken!
    }
  
    setAuthCurrentUser()

    apiPOST(
      "orders",
      params: params,
      success: { (responseObject, importedObjects) in
        
        let orderJson = responseObject["order"] as [String: AnyObject]
        self.saveUserDataFromResponse(orderJson["user"] as [String : AnyObject])
        
        if success != nil {
          success!(responseObject: responseObject, importedObjects: importedObjects)
        }
        
      },
      failure: failure
    )
  }
  
  func checkOrderStatus(order_id: String, success: APIRequestCustomSuccessBlock?, failure: APIRequestCustomFailureBlock?) {
    let path = "orders/\(order_id)"
    apiGET(
      path,
      params: nil,
      success: success,
      failure: failure
    )
  }
  

  // MARK: API calls - Discounts

  func getDiscount(discountCode: String, event: Event, success: APIRequestCustomSuccessBlock?, failure: APIRequestCustomFailureBlock?) {
    
    var params = [String: AnyObject]()
    params["event_id"] = event.uid.integerValue
    
    if UserDefaultsManager.loggedIn {
      params["user_email"] = UserDefaultsManager.email
    }

    apiGET(
      "discounts/\(discountCode)",
      params: params,
      success: success,
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
      
      CoreDataManager.saveMainContext()
    }
  }
  
  
  func apiRequestStandardFailure(failureBlock: APIRequestCustomFailureBlock?) -> (AFHTTPRequestOperation!, NSError!) -> Void {
    
    return {
      (operation: AFHTTPRequestOperation!, error: NSError!) in
      NSLog("APIClientManager: apiRequestStandardFailure() \n\(operation)\n\(error)")
      
      if operation.response != nil && operation.response!.statusCode >= 500 {
        // NOTE: if you don't want to show an alert for some actions,
        // like because you want the UI to be updated nicely instead of a brutal alert, you'll need to create an instance variable
        // like "alertOnUnmanagedErrors" that gets resetted after the failure block is executed

        UIAlertView(title: "This is embarrassing...", message: "You've found a bug in our system. We've got robots sending the error analysis to our engineers, who we hooked to coffee IVs. We've also alerted the president.", delegate: nil, cancelButtonTitle: "Cancel").show()
        
        AppHelpers.GA("soft_error", action: "api_client", label: error.localizedDescription, value: nil)
      }
      
      if failureBlock != nil {
        failureBlock!(responseObject: operation.responseObject as? [String: AnyObject], error: error)
      }
    }
  }
  
  
  func importObjectsToDatabase(dictionary: [String: AnyObject]) -> [NSManagedObject] {
    
    var allImportedObjects = [NSManagedObject]()
    let localContext = CoreDataManager.sharedInstance.mainContext
    
    for (key, object) in dictionary {
      var localEntityName = ServerJSONKeysToLocalEntities[key as String]
      var justImportedObjects: [NSManagedObject] = []
      
      if localEntityName != nil {
        var managedObjectClass = NSClassFromString(localEntityName) as NSManagedObject.Type
        
        if object as? NSDictionary != nil {
          justImportedObjects = [managedObjectClass.MR_importFromObject(object as [String: AnyObject], inContext: localContext)]
        } else if object as? NSArray != nil {
          justImportedObjects = managedObjectClass.MR_importFromArray(object as [[String: AnyObject]], inContext: localContext) as [NSManagedObject]
        }
      }
      
      for importedObject in justImportedObjects {
        allImportedObjects.append(importedObject)
      }
      
    }
    
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
  
  func setFacebookToken(var params: [String: AnyObject]?) -> [String: AnyObject] {

    if params == nil {
      params = [String: AnyObject]()
    }
    
    if UserDefaultsManager.fbAccessToken != nil {
      params!["facebook_id"] = UserDefaultsManager.fbAccessToken
    }
    
    return params!
  }
  
  func buildOrderParams(cart: Cart) -> [String: AnyObject] {
    
    var params = [
      "client_calculated_total": cart.total(),
      "event_id": cart.event.uid.integerValue,
      "integer_tip": cart.tipAmount(),
      "delivery_choice": cart.distribution_choice,
    ] as [String: AnyObject]
    
    if countElements(cart.notes) > 0 {
      params["notes"] = cart.notes
    }
    
    if cart.payment_type != nil {
      params["payment_type"] = cart.payment_type!
    }
    
    if cart.discount != nil {
      params["discount_name"] = cart.discount!.name
    }
    
    if cart.tier != nil {
      params["tier_id"] = cart.tier!.uid.integerValue
    }
    
    if cart.pickup_time != nil {
      params["pickup_time_id"] = cart.pickup_time!.uid.integerValue
    }
    
    var itemsParams = [AnyObject]()
    
    for cartItem in cart.getItemsObjects() {
      var itemParams = [
        "inventory_id": cartItem.inventory.uid.integerValue,
        "quantity": cartItem.quantity.integerValue
      ] as [String: AnyObject]
      
      var itemOptionsParams = [AnyObject]()
      
      for cartItemOption in cartItem.getOptionsObjects() {
        itemOptionsParams.append([
          "inventory_option_id": cartItemOption.inventory_option.uid.integerValue
        ])
      }
      
      itemParams["options_attributes"] = itemOptionsParams
      
      itemsParams.append(itemParams)
    }
    
    params["order_items_attributes"] = itemsParams
    
    return params
  }
  
  func preRequestReachabilityCheck(alertWhenUnreachable: Bool) -> Bool {
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    if alertWhenUnreachable && !appDelegate.currentlyReachable {
      UIAlertView(title: "No Internets", message: "We could not connect you. Tell everyone around you to stop being a jerk and turn off their phone.", delegate: nil, cancelButtonTitle: "Try again").show()
      AppHelpers.GA("soft_error", action: "api_client", label: "unreachable", value: nil)
    }
    
    return appDelegate.currentlyReachable
  }
  
  func saveUserDataFromResponse(userObject: [String: AnyObject]) {
    
    UserDefaultsManager.name = userObject["name"] as? String
    UserDefaultsManager.integerCredits = userObject["integer_credits"]! as Int
    UserDefaultsManager.discountCode = userObject["discount_code"] as? String
    UserDefaultsManager.discountIntegerValue = userObject["discount_integer_value"]! as Int
    UserDefaultsManager.currency = userObject["currency"] as? String
    
  }

  // MARK: - Core Data
  lazy var coreDataManager: CoreDataManager = {
    return CoreDataManager.sharedInstance
  }()
  
  // MARK: - NSCoding Protocol
  
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
*/
  
}
//
//private let APIClientManagerSharedInstance = APIClientManager()
//typealias APIRequestCustomSuccessBlock = (responseObject: [String: AnyObject], importedObjects: [NSManagedObject]) -> Void
//typealias APIRequestCustomFailureBlock = (responseObject: [String: AnyObject]?, error: NSError?) -> Void
//let ServerJSONKeysToLocalEntities:[String: String] = [
//  "events": "Crumpets.Event",
//  "event": "Crumpets.Event", // used in the inventory request to return the event's updated_at
//  "venues": "Crumpets.Venue",
//  "inventories": "Crumpets.Inventory",
//  "discount": "Crumpets.Discount",
//  "tiers": "Crumpets.Tier",
//  "concessions": "Crumpets.Concession"
//]
