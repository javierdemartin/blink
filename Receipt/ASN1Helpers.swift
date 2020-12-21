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

func readASN1Data(ptr: UnsafePointer<UInt8>, length: Int) -> Data {
  return Data(bytes: ptr, count: length)
}

func readASN1Integer(ptr: inout UnsafePointer<UInt8>?, maxLength: Int) -> Int? {
  var type: Int32 = 0
  var xclass: Int32 = 0
  var length: Int = 0
  
  ASN1_get_object(&ptr, &length, &type, &xclass, maxLength)
  guard type == V_ASN1_INTEGER else {
    return nil
  }
  let integerObject = c2i_ASN1_INTEGER(nil, &ptr, length)
  let intValue = ASN1_INTEGER_get(integerObject)
  ASN1_INTEGER_free(integerObject)
  
  return intValue
}

func readASN1String(ptr: inout UnsafePointer<UInt8>?, maxLength: Int) -> String? {
  var strClass: Int32 = 0
  var strLength = 0
  var strType: Int32 = 0
  
  var strPointer = ptr
  ASN1_get_object(&strPointer, &strLength, &strType, &strClass, maxLength)
  if strType == V_ASN1_UTF8STRING {
    let p = UnsafeMutableRawPointer(mutating: strPointer!)
    let utfString = String(bytesNoCopy: p, length: strLength, encoding: .utf8, freeWhenDone: false)
    return utfString
  }
  
  if strType == V_ASN1_IA5STRING {
    let p = UnsafeMutablePointer(mutating: strPointer!)
    let ia5String = String(bytesNoCopy: p, length: strLength, encoding: .ascii, freeWhenDone: false)
    return ia5String
  }
  
  return nil
}

func readASN1Date(ptr: inout UnsafePointer<UInt8>?, maxLength: Int) -> Date? {
  var str_xclass: Int32 = 0
  var str_length = 0
  var str_type: Int32 = 0
  
  // A date formatter to handle RFC 3339 dates in the GMT time zone
  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
  formatter.timeZone = TimeZone(abbreviation: "GMT")
  
  var strPointer = ptr
  ASN1_get_object(&strPointer, &str_length, &str_type, &str_xclass, maxLength)
  guard str_type == V_ASN1_IA5STRING else {
    return nil
  }

  let p = UnsafeMutableRawPointer(mutating: strPointer!)
  if let dateString = String(bytesNoCopy: p, length: str_length, encoding: .ascii, freeWhenDone: false) {
    return formatter.date(from: dateString)
  }

  return nil
}
