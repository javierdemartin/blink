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

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

extension Notification.Name {
  static let IAPHelperPurchaseNotification = Notification.Name("IAPHelperPurchaseNotification")
}

protocol IAPHelperDelegate: class {
  
  func didFail(with error: String)
  /**
   Finished retrieving available products (In App Purchases) from App Store Connect
   */
  func gotProductIdentifiersAndPricing(products: [SKProduct])
  func finishedRestoringPurchases()
}

open class IAPHelper: NSObject {
  
  private let productIdentifiers: Set<ProductIdentifier>
  private var purchasedProductIdentifiers: Set<ProductIdentifier> = []
  private var productsRequest: SKProductsRequest?
  private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
  
  weak var delegate: IAPHelperDelegate?
  
  public init(productIds: Set<ProductIdentifier>) {
    
    productIdentifiers = productIds
    super.init()
    
    SKPaymentQueue.default().add(self)
  }
}

extension IAPHelper: SKRequestDelegate {
  
  public func requestDidFinish(_ request: SKRequest) {
    dump(request)
  }
}

// MARK: - StoreKit API
extension IAPHelper {
  
  public func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
    productsRequest?.cancel()
    productsRequestCompletionHandler = completionHandler
    
    productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
    productsRequest?.delegate = self
    productsRequest?.start()
  }
  
  public func buyProduct(_ product: SKProduct) {
    // App should not add payments to the queue if the device is not authorized to do so
    if !IAPHelper.canMakePayments() { return }
    
    let payment = SKPayment(product: product)
    SKPaymentQueue.default().add(payment)
  }
  
  public class func canMakePayments() -> Bool {
    return SKPaymentQueue.canMakePayments()
  }
  
  /**
    Restore/Install purchases on additional devices or that the user deleted and has reinstalled.
   */
  public func restorePurchases() {
    SKPaymentQueue.default().restoreCompletedTransactions()
  }
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {
  
  /**
    Called by the delegate when `restoreCompletedTransactions()` **succeeds**.
   */
  public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
    
  }
  
  /**
    Called by the delegate when `restoreCompletedTransactions()` **fails**
   */
  public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
    print(error.localizedDescription)
  }
  
  /**
   Receives the app-requested information such as the In App Purchases content
   */
  public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    // Contains all of the available In App Purchases listed in App Store Connect
    let products = response.products
    productsRequestCompletionHandler?(true, products)
    clearRequestAndHandler()
    
    delegate?.gotProductIdentifiersAndPricing(products: products)
  }
  
  public func request(_ request: SKRequest, didFailWithError error: Error) {
    print("Failed to load list of products.")
    print("Error: \(error.localizedDescription)")
    productsRequestCompletionHandler?(false, nil)
    clearRequestAndHandler()
  }
  
  private func clearRequestAndHandler() {
    productsRequest = nil
    productsRequestCompletionHandler = nil
  }
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
  
  public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchased:
        // Successfully processed transaction
        complete(transaction: transaction)
      case .failed:
        fail(transaction: transaction)
      case .restored:
        restore(transaction: transaction)
      case .deferred:
        break
      case .purchasing:
        // Presented the buying sheet, awaiting for the user's transaction...
        break
      @unknown default:
        fatalError()
      }
    }
  }
  
  /**
   Notify the App Store that the app has finished processing the transaction. Transactions on the payment queue are persistent
   until they are completed. After finishing processing a transaction in your app always call the `finishTransaction`method
   to finish the transaction and remove it from the queue.
   */
  private func complete(transaction: SKPaymentTransaction) {
    SKPaymentQueue.default().finishTransaction(transaction)
    
    guard let receiptString = ReceiptFetcher.sharedInstance().fetchReceipt() else {
      return
    }
    
    ReceiptFetcher.sharedInstance().validate(receipt: receiptString, completion: {
      self.delegate?.finishedRestoringPurchases()
    })
    
  }
  
  private func restore(transaction: SKPaymentTransaction) {
    guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
    
    // Get the receipt if it's available
    if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
       FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
      
      do {
        let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
//        print(receiptData)
        
        let receiptString = receiptData.base64EncodedString(options: [])
        
        // Read receiptData
//        print(receiptString)
        
        ReceiptFetcher.sharedInstance().validate(receipt: receiptString, completion: {
          self.delegate?.finishedRestoringPurchases()
        })
        
      } catch {
        print("Couldn't read receipt data with error: " + error.localizedDescription)
      }
    }
    
    print("restore... \(productIdentifier)")
    SKPaymentQueue.default().finishTransaction(transaction)
  }
  
  private func fail(transaction: SKPaymentTransaction) {
    print("fail...")
    if let transactionError = transaction.error as NSError?,
       let localizedDescription = transaction.error?.localizedDescription,
       transactionError.code != SKError.paymentCancelled.rawValue {
      print("Transaction Error: \(localizedDescription)")
      delegate?.didFail(with: localizedDescription)
    }
    
    SKPaymentQueue.default().finishTransaction(transaction)
  }
}

