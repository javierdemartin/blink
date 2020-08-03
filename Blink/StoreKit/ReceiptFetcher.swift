//////////////////////////////////////////////////////////////////////////////////
//
// B L I N K
//
// Copyright (C) 2016-2019 Blink Mobile Shell Project
//
// This file is part of Blink.
//
// Blink is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Blink is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Blink. If not, see <http://www.gnu.org/licenses/>.
//
// In addition, Blink is also subject to certain additional terms under
// GNU GPL version 3 section 7.
//
// You should have received a copy of these additional terms immediately
// following the terms and conditions of the GNU General Public License
// which accompanied the Blink Source Code. If not, see
// <http://www.github.com/blinksh/blink>.
//
////////////////////////////////////////////////////////////////////////////////

import StoreKit

enum ReceiptValidationError: Error {
  case receiptNotFound
  case jsonResponseIsNotValid(description: String)
  case notBought
  case expired
}


/**
 Refreshes the local receipt.
 */
@objc class ReceiptFetcher : NSObject {
  
  /**
   Fetches the receipt if it's invalid or missing.
   */
  let receiptRefreshRequest = SKReceiptRefreshRequest()
  
  @objc private static let _shared = ReceiptFetcher()
  private override init() {
    // Prevents others from using the default '()' initializer for this class.
    
    super.init()
    // SKRequestDelegate methods are called just when the
    // receipt  is retrieved
    receiptRefreshRequest.delegate = self
    
    SKPaymentQueue.default().add(self)
  }
  
  // sharedInstance class methoc can be reached from Objective-C
  @objc class func sharedInstance() -> ReceiptFetcher {
    return _shared
  }
  
  /**
   Number of days since initial purchase
   */
  @objc public var daysInUse: Int = -1
  
  /**
    Shown in `BKSettingsViewController` to show the user a detail of their current suscription purchased
   */
  @objc public var currentSuscription: String = "Not suscribed"
  
  @objc public var currentSuscriptionExpirationDateString: String = "" // Date(timeIntervalSince1970: 0)
  @objc public var currentSuscriptionExpirationDate: String = "" //Date(timeIntervalSince1970: 0)
  
  @objc public var hasBoughtOgBlink = false
  
  /**
   First app version that was acquired in the AppStore
   */
  @objc var initialAppVersion: String = ""
  
  @objc func fetchReceipt() -> String? {
    
    // Locates the receipt and points to where it's located
    guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
      // No receipt was found.
      return nil
    }
    
    do {
      
      let reachable = try receiptUrl.checkResourceIsReachable()
      
      // The receipt does not exist, start refreshing
      if reachable == false {
        receiptRefreshRequest.start()
      }
      
      if FileManager.default.fileExists(atPath: receiptUrl.path) {
        
        do {
          
          let receiptData = try Data(contentsOf: receiptUrl, options: .alwaysMapped)
          let receiptString = receiptData.base64EncodedString()
          
          return receiptString
          
          
          
        } catch {
          print(error.localizedDescription)
        }
      }
    } catch {
      /** The receipt doesn't exist, start the refresh process. If it's not present the error will be:
       `error: The file “sandboxReceipt” couldn’t be opened because there is no such file`
       */ 
      print("Error: \(error.localizedDescription)")
      self.receiptRefreshRequest.start()
    }
    
    return nil
  }
  
  /**
   Validates the receipt against the server
   - Parameters:
    - receipt: Base64 encoded receipt read from the device
    - completion: `(() -> Void)? = nil` Optional, needed only if you need to perform an operation later when the receipt has been validated against the server.
   */
  @objc func validate(receipt: String, completion: (() -> Void)? = nil) {
    
    do {
      
      let jsonObjectBody = ["receipt-data" : receipt]
      
      guard let url = URL(string: "http://192.168.86.25:8080/validateReceipt") else { return }
      
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      
      do {
        request.httpBody = try JSONSerialization.data(withJSONObject: jsonObjectBody, options: .prettyPrinted)
      } catch let error {
        print(error.localizedDescription)
      }
      
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.addValue("application/json", forHTTPHeaderField: "Accept")
      
      let semaphore = DispatchSemaphore(value: 0)
      
      var validationError : ReceiptValidationError?
      
      let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data,
              let httpResponse = response as? HTTPURLResponse,
              error == nil,
              httpResponse.statusCode == 200
        else {
          validationError = ReceiptValidationError.jsonResponseIsNotValid(description: error?.localizedDescription ?? "")
          semaphore.signal()
          return
        }
        
        guard let jsonResponse = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [AnyHashable: Any] else {
          validationError = ReceiptValidationError.jsonResponseIsNotValid(description: "Unable to parse json")
          semaphore.signal()
          return
        }
        
        /**
         * Validation sends a `status: 21004` code if user is currently suscribed to an IAP and no App-Shared secret was provided in the URL request
         */
        guard let status = jsonResponse["status"] as? Int else { return }
                
        if let latestReceiptInfo = jsonResponse["latest_receipt_info"] as? [[AnyHashable: Any]] {
          
          for purchase in latestReceiptInfo {
            
            let expiresDateValue = Double(purchase["expires_date_ms"] as! String)! / 1000.0
            let expiresDate = Date(timeIntervalSince1970: expiresDateValue)
            
            if Date() > expiresDate {
              // No active suscription
            } else {
              // Active suscription
              self.currentSuscription = purchase["product_id"] as! String
              self.currentSuscriptionExpirationDate = "\(Calendar.dateIntervalBetweenDates(startDate: expiresDate, endDate: Date())!)"
              self.currentSuscriptionExpirationDateString = expiresDate.description(with: .current)
            }
          }
        }
        
        self.localReceiptValidation()
        
        guard let jsonReceiptData = jsonResponse["receipt"] as? [AnyHashable: Any] else {
          semaphore.signal()
          return
        }
        
        guard let originalPurchaseDate = jsonReceiptData["original_purchase_date_ms"] as? String else {
          semaphore.signal()
          return
        }
        
        guard let originalPurchaseDateTimeInterval = TimeInterval(originalPurchaseDate) else {
          semaphore.signal()
          return
        }
        
        guard let originalAppVersion = jsonReceiptData["original_application_version"] as? String else {
          semaphore.signal()
          return
        }
        
        let shiftDate = Date(timeIntervalSince1970: (originalPurchaseDateTimeInterval / 1000.0))
        
        guard let daysInUse = Calendar.daysBetweenDates(startDate: Date(), endDate: shiftDate) else {
          return
        }
        
        self.daysInUse = daysInUse
        self.initialAppVersion = originalAppVersion
        
        semaphore.signal()
        
        completion?()
      }
      
      task.resume()
      
      semaphore.wait()
      
      if let validationError = validationError {
        throw validationError
      }
      
    } catch {
      print(error.localizedDescription)
    }
  }
  
  /**
   Perform local data validation for the receipt.
   */
  func localReceiptValidation(jsonResponse: [AnyHashable: Any]) {
    
    guard let jsonReceiptData = jsonResponse["receipt"] as? [AnyHashable: Any] else {
      semaphore.signal()
      return
    }
    
    
    
  }
}

// MARK: SKRequestDelegate
extension ReceiptFetcher: SKRequestDelegate {
  
  /**
    `SKReceiptRefreshRequest` has finished
   */
  func requestDidFinish(_ request: SKRequest) {
    print("request finished successfully")
  }
  
  func request(_ request: SKRequest, didFailWithError error: Error) {
    print("request failed with error \(error.localizedDescription)")
  }
}

// MARK: SKPaymentTransactionObserver
extension ReceiptFetcher: SKPaymentTransactionObserver {
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    print("\(#function)")
  }
}
