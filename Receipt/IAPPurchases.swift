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

struct IAPPurchases {
  
  var quantity: Int?
  var productIdentifier: String?
  var transactionIdentifer: String?
  var originalTransactionIdentifier: String?
  var purchaseDate: Date?
  var originalPurchaseDate: Date?
  var subscriptionExpirationDate: Date?
  var subscriptionIntroductoryPricePeriod: Int?
  var subscriptionCancellationDate: Date?
  var webOrderLineId: Int?
  
  init?(with pointer: inout UnsafePointer<UInt8>?, payloadLength: Int) {
    
    let endPointer = pointer!.advanced(by: payloadLength)
    var type: Int32 = 0
    var xclass: Int32 = 0
    var length = 0
    
    ASN1_get_object(&pointer, &length, &type, &xclass, payloadLength)
    guard type == V_ASN1_SET else {
      return nil
    }
    
    while pointer! < endPointer {
      ASN1_get_object(&pointer, &length, &type, &xclass, pointer!.distance(to: endPointer))
      guard type == V_ASN1_SEQUENCE else {
        return nil
      }
      guard let attributeType = readASN1Integer(ptr: &pointer,
                                                maxLength: pointer!.distance(to: endPointer))
        else {
          return nil
      }
      // Attribute version must be an integer, but not using the value
      guard let _ = readASN1Integer(ptr: &pointer,
                                    maxLength: pointer!.distance(to: endPointer))
        else {
          return nil
      }
      ASN1_get_object(&pointer, &length, &type, &xclass, pointer!.distance(to: endPointer))
      guard type == V_ASN1_OCTET_STRING else {
        return nil
      }
      
      switch attributeType {
      case 1701:
        var p = pointer
        quantity = readASN1Integer(ptr: &p, maxLength: length)
      case 1702:
        var p = pointer
        productIdentifier = readASN1String(ptr: &p, maxLength: length)
      case 1703:
        var p = pointer
        transactionIdentifer = readASN1String(ptr: &p, maxLength: length)
      case 1705:
        var p = pointer
        originalTransactionIdentifier = readASN1String(ptr: &p, maxLength: length)
      case 1704:
        var p = pointer
        purchaseDate = readASN1Date(ptr: &p, maxLength: length)
      case 1706:
        var p = pointer
        originalPurchaseDate = readASN1Date(ptr: &p, maxLength: length)
      case 1708:
        var p = pointer
        subscriptionExpirationDate = readASN1Date(ptr: &p, maxLength: length)
      case 1712:
        var p = pointer
        subscriptionCancellationDate = readASN1Date(ptr: &p, maxLength: length)
      case 1711:
        var p = pointer
        webOrderLineId = readASN1Integer(ptr: &p, maxLength: length)
      default:
        break
      }
      
      pointer = pointer!.advanced(by: length)
    }
  }
}
