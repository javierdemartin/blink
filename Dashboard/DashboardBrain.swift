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
import Combine

/**
 Brains of the Dashboard that publish and interact with the actions performed.
 
 Used to handle events such as timers or notifications. Publishes the data valus for
 which it is responsible as published properties. Observer objects then subscribe to the publisher and receive updates whenever canges to the @Published properties occur.
 */
class DashboardBrain: ObservableObject {
  
  /// Identified URLs
  @Published var urls: [String] = []
  
  /// Recent downloads
  @Published var downloads: [String] = []
  
  /// Action executed by an element
  @Published var dashboardAction = PassthroughSubject<BKDashboardAction, Never>()
  
  /// Consecuence of an action, used to update the interface after
  @Published var dashboardConsecuence = PassthroughSubject<BKDashboardConsequence, Never>()
  
  /// Identifier of active `TerminalControllers`
  @Published var activeTerminalControllers: [BrainSessionData] = []
  
  @Published var activeSession: UUID?
  
  // TODO: Define how to keep track of current sessions and associated tunnel.
}

struct BrainSessionData {
  var id: UUID
  var title: String?
  /// TODO: Get current proces of the terminal to show it on the carrousel
  /// TODO: Get more info to show in the Term carrousel
}
