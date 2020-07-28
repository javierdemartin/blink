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


//#if DEBUG
//let urlString = "https://sandbox.itunes.apple.com/verifyReceipt"
//#else
//let urlString = "https://buy.itunes.apple.com/verifyReceipt"
//#endif

// https://fluffy.es/migrate-paid-app-to-iap/
// https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html

enum ReceiptValidationError: Error {
  case receiptNotFound
  case jsonResponseIsNotValid(description: String)
  case notBought
  case expired
}

struct ReceiptDataToShow {
  
  let originalPurchasedVersion: String
  let daysInUse: Int
}

import StoreKit

@objc
class ReceiptFetcher : NSObject, SKRequestDelegate {
  let receiptRefreshRequest = SKReceiptRefreshRequest()
  
  @objc static let shared = ReceiptFetcher()
  private override init() {
    //This prevents others from using the default '()' initializer for this class.
    
    super.init()
    // set delegate to self so when the receipt is retrieved,
    // the delegate methods will be called
    receiptRefreshRequest.delegate = self
    
    SKPaymentQueue.default().add(self)
    
//    fetchReceipt()
  }
  
  // sharedInstance class methoc can be reached from Objective-C
  @objc class func sharedInstance() -> ReceiptFetcher {
    return shared
  }
  
  
  @objc public var daysInUse: Int = -1
  @objc var initialAppVersion: String = ""
  
  
  
  @objc func fetchReceipt() {
    guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
      print("unable to retrieve receipt url")
      return
    }
    
    do {
      // if the receipt does not exist, start refreshing
      let reachable = try receiptUrl.checkResourceIsReachable()
      
      // the receipt does not exist, start refreshing
      if reachable == false {
        receiptRefreshRequest.start()
      }
      
      if FileManager.default.fileExists(atPath: receiptUrl.path) {
        
        do {
          
          let receiptData = try! Data(contentsOf: receiptUrl, options: .alwaysMapped)
          let receiptString = receiptData.base64EncodedString()
          
          let jsonObjectBody = ["receipt-data" : receiptString]
          
          //          #if DEBUG
          //          let url = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
          //          #else
          //          let url = URL(string: "https://buy.itunes.apple.com/verifyReceipt")!
          //          #endif
          
          let url = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
          
          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          request.httpBody = try! JSONSerialization.data(withJSONObject: jsonObjectBody, options: .prettyPrinted)
          
          let semaphore = DispatchSemaphore(value: 0)
          
          var validationError : ReceiptValidationError?
          
          let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil, httpResponse.statusCode == 200 else {
              validationError = ReceiptValidationError.jsonResponseIsNotValid(description: error?.localizedDescription ?? "")
              semaphore.signal()
              return
            }
            guard let jsonResponse = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [AnyHashable: Any] else {
              validationError = ReceiptValidationError.jsonResponseIsNotValid(description: "Unable to parse json")
              semaphore.signal()
              return
            }
            
            dump(jsonResponse)
            
            guard let jsonReceiptData = jsonResponse["receipt"] as? [AnyHashable: Any] else {
              return
            }
            
            guard let originalPurchaseDate = jsonReceiptData["original_purchase_date_ms"] as? String else {
              return
            }
            
            guard let originalPurchaseDateTimeInterval = TimeInterval(originalPurchaseDate) else {
              return
            }
            
            dump(originalPurchaseDate)
            
            guard let originalAppVersion = jsonReceiptData["original_application_version"] as? String else {
              return
            }
            
            let shiftDate = Date(timeIntervalSince1970: (originalPurchaseDateTimeInterval / 1000.0))
            
            let calendar = Calendar.current
            
            // Replace the hour (time) of both dates with 00:00
            let date1 = calendar.startOfDay(for: Date())
            let date2 = calendar.startOfDay(for: shiftDate)
            
            let components = calendar.dateComponents([.day], from: date2, to: date1)
            
            guard let daysInUse = components.day else {
              return
            }
            
            self.daysInUse = daysInUse
            self.initialAppVersion = originalAppVersion
            
            semaphore.signal()
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
    } catch {
      // the receipt does not exist, start refreshing
      
      print("error: \(error.localizedDescription)")
      /*
       error: The file “sandboxReceipt” couldn’t be opened because there is no such file
       */
      self.receiptRefreshRequest.start()
    }
  }
  
  // MARK: SKRequestDelegate methods
  func requestDidFinish(_ request: SKRequest) {
    print("request finished successfully")
  }
  
  func request(_ request: SKRequest, didFailWithError error: Error) {
    print("request failed with error \(error.localizedDescription)")
  }
}

extension ReceiptFetcher: SKPaymentQueueDelegate {
  
}

extension ReceiptFetcher: SKPaymentTransactionObserver {
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    print("\(#function)")
  }
}
