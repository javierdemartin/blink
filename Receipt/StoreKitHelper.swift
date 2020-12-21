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

import Foundation
import StoreKit

enum ReceiptError: Error {
  case noReceiptFoundInBundle
  case other(cause: Error)
}

// TODO: Show user's the status of their receipt if it's a bad result
enum ReceiptStatus: String {
  case validationSuccess = "This receipt is valid."
  case noReceiptOnDevice = "A receipt was not found on this device."
  case unknownFailure = "An unexpected failure occurred during verification."
  case unknownReceiptFormat = "The receipt is not in PKCS7 format."
  case invalidPKCS7Signature = "Invalid PKCS7 Signature."
  case invalidPKCS7Type = "Invalid PKCS7 Type."
  case invalidAppleRootCertificate = "Public Apple root certificate not found."
  case failedAppleSignature = "Receipt not signed by Apple."
  case unexpectedASN1Type = "Unexpected ASN1 Type."
  case missingComponent = "Expected component was not found."
  case invalidBundleIdentifier = "Receipt bundle identifier does not match application bundle identifier."
  case invalidVersionIdentifier = "Receipt version identifier does not match application version."
  case invalidHash = "Receipt failed hash check."
  case invalidExpired = "Receipt has expired."
}

@objc class StoreKitHelper: NSObject {
  
  var receiptStatus: ReceiptStatus?
  var bundleIdString: String?
  var bundleVersionString: String?
  var bundleIdData: Data?
  var hashData: Data?
  var opaqueData: Data?
  var expirationDate: Date?
  var receiptCreationDate: Date?
  var originalAppVersion: String?
  var inAppReceipts: [IAPPurchases] = []
  
  private var completionHandler: ((Result<URL, ReceiptError>) -> Void)?
  
  let receiptRequest = SKReceiptRefreshRequest(receiptProperties: nil)
  
  private var appStoreUrl: URL? {
    get {
      return Bundle.main.appStoreReceiptURL
    }
  }
  
  private var receiptOnDevice: Bool {
    guard let path = appStoreUrl?.path else { return false }
    return FileManager().fileExists(atPath: path)
  }
  
  @objc override init() {
    
  }
  
  @objc func fetch(completion: @escaping (URL) -> Void) {
    
    if let appStoreUrl = Bundle.main.appStoreReceiptURL {
      completion(appStoreUrl)
    } else {
      receiptRequest.delegate = self
      receiptRequest.start()
    }
  }
  
  @objc func parse(url: URL) {
    guard let receiptData = try? Data(contentsOf: url) else {
      receiptStatus = .noReceiptOnDevice
      return
    }
    
    let receiptBIO = BIO_new(BIO_s_mem())
    let receiptBytes: [UInt8] = .init(receiptData)
    
    BIO_write(receiptBIO, receiptBytes, Int32(receiptData.count))
    
    let receiptPKCS7 = d2i_PKCS7_bio(receiptBIO, nil)
    BIO_free(receiptBIO)
    
    guard receiptPKCS7 != nil else {
      receiptStatus = .unknownReceiptFormat
      return
    }
    
    guard OBJ_obj2nid(receiptPKCS7!.pointee.type) == NID_pkcs7_signed else {
      receiptStatus = .invalidPKCS7Signature
      return
    }
    
    let receiptContents = receiptPKCS7!.pointee.d.sign.pointee.contents
    
    guard OBJ_obj2nid(receiptContents?.pointee.type) == NID_pkcs7_data else {
      receiptStatus = .invalidPKCS7Type
      return
    }
    
    guard validateSigning(receiptPKCS7) else {
      return
    }
    
    readReceipt(receiptPKCS7)
    
    validateReceipt()
    
    hasActiveSubscriptions()
  }
  
  func hasActiveSubscriptions() {
    
    let today = Date()
    
    guard let activeSubscription = inAppReceipts.filter({ $0.subscriptionExpirationDate != nil }).filter({ $0.subscriptionExpirationDate! > today }) .first else {
      BKDefaults.setActiveSubscription(nil)
      return
    }
    
    guard let productIdentifier = activeSubscription.productIdentifier else {
      return
    }
    
    BKDefaults.setActiveSubscription(productIdentifier)
  }
  
  private func getDeviceIdentifier() -> Data {
    let device = UIDevice.current
    var uuid = device.identifierForVendor!.uuid
    let addr = withUnsafePointer(to: &uuid) { (p) -> UnsafeRawPointer in
      UnsafeRawPointer(p)
    }
    let data = Data(bytes: addr, count: 16)
    return data
  }
  
  func validateReceipt() {
    
    guard
      let idString = bundleIdString,
      let version = bundleVersionString,
      let _ = opaqueData,
      let hash = hashData
    else {
      receiptStatus = .missingComponent
      return
    }
    
    guard let appBundleId = Bundle.main.bundleIdentifier else {
      receiptStatus = .unknownFailure
      return
    }
    
    guard idString == appBundleId else {
      receiptStatus = .invalidBundleIdentifier
      return
    }
    
    // Check the version
    guard let appVersionString =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
      receiptStatus = .unknownFailure
      return
    }
    guard version == appVersionString else {
      receiptStatus = .invalidVersionIdentifier
      return
    }
    
    // Check the GUID hash
    let guidHash = computeHash()
    guard hash == guidHash else {
      receiptStatus = .invalidHash
      return
    }
    
    // Check the expiration attribute if it's present
    let currentDate = Date()
    if let expirationDate = expirationDate {
      if expirationDate < currentDate {
        receiptStatus = .invalidExpired
        return
      }
    }
    
    receiptStatus = .validationSuccess
  }
  
  private func validateSigning(_ receipt: UnsafeMutablePointer<PKCS7>?) -> Bool {
    guard
      let rootCertUrl = Bundle.main
        .url(forResource: "AppleIncRootCertificate", withExtension: "cer"),
      let rootCertData = try? Data(contentsOf: rootCertUrl)
    else {
      receiptStatus = .invalidAppleRootCertificate
      return false
    }
    
    let rootCertBio = BIO_new(BIO_s_mem())
    let rootCertBytes: [UInt8] = .init(rootCertData)
    BIO_write(rootCertBio, rootCertBytes, Int32(rootCertData.count))
    let rootCertX509 = d2i_X509_bio(rootCertBio, nil)
    BIO_free(rootCertBio)
    
    let store = X509_STORE_new()
    X509_STORE_add_cert(store, rootCertX509)
    
    //    OPENSSL_init_crypto(UInt64(OPENSSL_INIT_ADD_ALL_DIGESTS), nil)
    
    let verificationResult = PKCS7_verify(receipt, nil, store, nil, nil, 0)
    guard verificationResult == 1  else {
      receiptStatus = .failedAppleSignature
      return false
    }
    
    return true
    
  }
  
  private func computeHash() -> Data {
    
    let identifierData = getDeviceIdentifier()
    var ctx = SHA_CTX()
    SHA1_Init(&ctx)
    
    let identifierBytes: [UInt8] = .init(identifierData)
    SHA1_Update(&ctx, identifierBytes, identifierData.count)
    
    let opaqueBytes: [UInt8] = .init(opaqueData!)
    SHA1_Update(&ctx, opaqueBytes, opaqueData!.count)
    
    let bundleBytes: [UInt8] = .init(bundleIdData!)
    SHA1_Update(&ctx, bundleBytes, bundleIdData!.count)
    
    var hash: [UInt8] = .init(repeating: 0, count: 20)
    SHA1_Final(&hash, &ctx)
    return Data(bytes: hash, count: 20)
  }
  
  private func readReceipt(_ receiptPKCS7: UnsafeMutablePointer<PKCS7>?) {
    
    // Pointer to the start & end of the ASN.1 payload
    let receiptSign = receiptPKCS7?.pointee.d.sign
    let octets = receiptSign?.pointee.contents.pointee.d.data
    var ptr = UnsafePointer(octets?.pointee.data)
    let end = ptr!.advanced(by: Int(octets!.pointee.length))
    
    var type: Int32 = 0
    var xclass: Int32 = 0
    var length: Int = 0
    
    ASN1_get_object(&ptr, &length, &type, &xclass, ptr!.distance(to: end))
    
    guard type == V_ASN1_SET else {
      return
    }
    
    while ptr! < end {
      
      ASN1_get_object(&ptr, &length, &type, &xclass, ptr!.distance(to: end))
      guard type == V_ASN1_SEQUENCE else {
        receiptStatus = .unexpectedASN1Type
        return
      }

      guard let attributeType = readASN1Integer(ptr: &ptr, maxLength: length) else {
        receiptStatus = .unexpectedASN1Type
        return
      }
      
      guard let _ = readASN1Integer(ptr: &ptr, maxLength: ptr!.distance(to: end)) else {
        receiptStatus = .unexpectedASN1Type
        return
      }
      
      ASN1_get_object(&ptr, &length, &type, &xclass, ptr!.distance(to: end))
      guard type == V_ASN1_OCTET_STRING else {
        receiptStatus = .unexpectedASN1Type
        return
      }
      
      switch attributeType {
      case 2:
        var stringStartPtr = ptr
        bundleIdString = readASN1String(ptr: &stringStartPtr, maxLength: length)
        bundleIdData = readASN1Data(ptr: ptr!, length: length)
        
      case 3:
        var stringStartPtr = ptr
        bundleVersionString = readASN1String(ptr: &stringStartPtr, maxLength: length)
        
      case 4:
        let dataStartPtr = ptr!
        opaqueData = readASN1Data(ptr: dataStartPtr, length: length)
        
      case 5:
        let dataStartPtr = ptr!
        hashData = readASN1Data(ptr: dataStartPtr, length: length)
        
      case 12:
        var dateStartPtr = ptr
        receiptCreationDate = readASN1Date(ptr: &dateStartPtr, maxLength: length)
        
      case 17:
        var iapStartPtr = ptr
        let parsedReceipt = IAPPurchases(with: &iapStartPtr, payloadLength: length)
        if let newReceipt = parsedReceipt {
          inAppReceipts.append(newReceipt)
        }
      case 19:
        var stringStartPtr = ptr
        originalAppVersion = readASN1String(ptr: &stringStartPtr, maxLength: length)
        
      case 21:
        var dateStartPtr = ptr
        expirationDate = readASN1Date(ptr: &dateStartPtr, maxLength: length)
        
      default:
        print("Not processing attribute type: \(attributeType)")
      }
      
      // Advance pointer to the next item
      ptr = ptr!.advanced(by: length)
    } 
  }
}

extension StoreKitHelper : SKRequestDelegate {
  
  func requestDidFinish(_ request: SKRequest) {
    
    guard receiptOnDevice, let appStoreReceiptURL = appStoreUrl else {
      completionHandler?(.failure(.noReceiptFoundInBundle))
      return
    }
    completionHandler?(.success(appStoreReceiptURL))
  }
  
  func request(_ request: SKRequest, didFailWithError error: Error) {
    completionHandler?(.failure(.other(cause: error)))
  }
}
