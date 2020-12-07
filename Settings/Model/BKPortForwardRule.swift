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

// TODO: Set up iCloud sync of the saved PortForward rules
class BKPortForwardRule: NSObject, NSCoding {
  
  enum CodingKeys : String, CodingKey {
    case id = "id"
    case label = "label"
    case tunnelType = "tunnelType"
    case portFrom = "portFrom"
    case portTo = "portTo"
    case destination = "destination"
    case enabled = "enabled"
    case cloudKitRecordId = "cloudKitRecordId"
  }
  
  var id = UUID()
  var label: String?
  var tunnelType: String
  var portFrom: String
  var portTo: String
  var destination: String
  var enabled: Bool = false
  
  func encode(with coder: NSCoder) {
    
    coder.encode(id, for: CodingKeys.id)
    coder.encode(label, for: CodingKeys.label)
    coder.encode(tunnelType, for: CodingKeys.tunnelType)
    coder.encode(portFrom, for: CodingKeys.portFrom)
    coder.encode(portTo, for: CodingKeys.portTo)
    coder.encode(destination, for: CodingKeys.destination)
  }
  
  required init?(coder: NSCoder) {
    
    id = coder.decode(for: CodingKeys.id)!
    label = coder.decode(for: CodingKeys.label)
    tunnelType = coder.decode(for: CodingKeys.tunnelType)!
    portFrom = coder.decode(for: CodingKeys.portFrom)!
    portTo = coder.decode(for: CodingKeys.portTo)!
    destination = coder.decode(for: CodingKeys.destination)!
    enabled = coder.decode(for: CodingKeys.enabled)
  }

  init(label: String?, type: SSHPortForwardType, portFrom: String, portTo: String, destination: String) {
    self.label = label
    self.tunnelType = type.rawValue
    self.portFrom = portFrom
    self.portTo = portTo
    self.destination = destination
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
