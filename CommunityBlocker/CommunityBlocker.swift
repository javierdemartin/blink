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

protocol CommunityBlockerDelegate: class {
  func startFading()
  /// Whenever the user shakes the device or shakes it dismiss the overlayed view
  func removeCommunityBlockerAfterTime()
}

class CommunityBlocker {
  
  var timer: Timer?
  
  weak var delegate: CommunityBlockerDelegate?
  
  /// Time (seconds) user has to use the app without bothering them
  let timeBetweenBanner: Double = 1200
  /// Time (seconds) to dismiss manually the full screen and go back to normal
  let timeToDismissManually: Double = 60.0
  /// Time (seconds) of the view's transition back to normal opacity
  let dismissDuration: Double = 5.0
  /// Duration of the fading in which opacity is changing from `1.0` to a lower value
  let fadingDuration: Double = 120.0
  
  
  
  init() {
    timer?.invalidate()
    timer = Timer.scheduledTimer(timeInterval: timeBetweenBanner, target: self, selector: #selector(startFading), userInfo: nil, repeats: false)
  }
  
  /**
   Start deceasing the opacity of the underlying views progressively
   */
  @objc func startFading() {
    delegate?.startFading()
  }
  
  /**
   In case the user can't phisically shake the device the view is going to be dismissed after a minute.
   */
  func startAutomaticDismissalTimer() {
    
    timer?.invalidate()
    timer = Timer.scheduledTimer(timeInterval: timeToDismissManually, target: self, selector: #selector(dismissAfterTimer), userInfo: nil, repeats: false)
  }
  
  /**
   Dismiss the overlays and start a new time
   */
  @objc func dismissAfterTimer() {
    delegate?.removeCommunityBlockerAfterTime()
    timer?.invalidate()
    timer = Timer.scheduledTimer(timeInterval: timeBetweenBanner, target: self, selector: #selector(startFading), userInfo: nil, repeats: false)
  }
  
  /**
   
   */
  func userAskedForMoreTime() {
    timer?.invalidate()
    timer = Timer.scheduledTimer(timeInterval: timeBetweenBanner, target: self, selector: #selector(startFading), userInfo: nil, repeats: false)
  }
}
