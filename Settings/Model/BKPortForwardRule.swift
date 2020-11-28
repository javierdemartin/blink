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
import CloudKit

enum SSHPortForwardType: String, Codable, CaseIterable {
  case local = "Local"
  case remote = "Remote"
  case dynamic = "Dynamic"
}

class BKPortForwardRule: NSObject, NSCoding {
  func encode(with coder: NSCoder) {
    coder.encode(label, for: CodingKeys.label)
    coder.encode(type, for: CodingKeys.type)
    coder.encode(portFrom, for: CodingKeys.portFrom)
    coder.encode(portTo, for: CodingKeys.portTo)
    coder.encode(destination, for: CodingKeys.destination)
    
  }
  
  required init?(coder: NSCoder) {
    // Can't store custom classes as a node in the file system as it has no notion of the existence of
    // https://stackoverflow.com/questions/4197246/storing-nsmutablearray-filled-with-custom-objects-in-nsuserdefaults-crash/4197319#4197319
    label = coder.decodeObject(forKey: "label") as? String
    type = coder.decodeObject(forKey: "type") as? String ?? ""
    portFrom = coder.decodeObject(forKey: "portFrom") as? String ?? ""
    portTo = coder.decodeObject(forKey: "portTo") as? String ?? ""
    destination = coder.decodeObject(forKey: "destination") as? String ?? ""
//    cloudKitRecordId = coder.decodeObject(forKey: "cloudKitRecordId") as! CKRecord.ID
  }
  
  var id = UUID()
  var label: String?
  var type: String
  var portFrom: String
  var portTo: String
  var destination: String
  var enabled: Bool = false
//  var cloudKitRecordId: CKRecord.ID
  
  enum CodingKeys : String, CodingKey {
    case label = "label"
    case type = "type"
    case portFrom = "portFrom"
    case portTo = "portTo"
    case destination = "destination"
    case enabled = "enabled"
    case cloudKitRecordId = "cloudKitRecordId"
  }
  
  init(label: String?, type: SSHPortForwardType, portFrom: String, portTo: String, destination: String) {
    self.label = label
    self.type = type.rawValue
    self.portFrom = portFrom
    self.portTo = portTo
    self.destination = destination
//    self.cloudKitRecordId = cloudKitRecordId
  }
  
  func load() {
    
  }
  
  static func deleteAtIndex(offset: IndexSet) {
    var loaded = BKPortForwardRule.all()
    loaded.remove(atOffsets: offset)
    
    do {
      let data = try NSKeyedArchiver.archivedData(withRootObject: loaded, requiringSecureCoding: false)
      try data.write(to: URL(fileURLWithPath: BlinkPaths.blinkPortForwardingRules()))
    } catch {
      fatalError("couldn't save file")
    }
  }
  
  static func save(label: String?, type: SSHPortForwardType, portFrom: String, portTo: String, destination: String) {
    let rule = BKPortForwardRule(label: label, type: type, portFrom: portFrom, portTo: portTo, destination: destination)
    
    var rules = BKPortForwardRule.all()
    rules.append(rule)
    
    do {
      let data = try NSKeyedArchiver.archivedData(withRootObject: rules, requiringSecureCoding: false)
      try data.write(to: URL(fileURLWithPath: BlinkPaths.blinkPortForwardingRules()))
    } catch {
      fatalError("couldn't save file")
    }
  }
  
  func save() {
    
  }
  
  func update() {
    
  }
  
  static func all() -> [BKPortForwardRule] {
    
    guard  let data = try? Data(contentsOf: URL(fileURLWithPath: BlinkPaths.blinkPortForwardingRules()), options: []) else {
      print("No data found at location")
      return []
    }
    
    guard  let loadedUserData = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [BKPortForwardRule] else {
                print("Couldn't read user data file.");
                return []
            }
    
    
    
    return loadedUserData
  }
}
