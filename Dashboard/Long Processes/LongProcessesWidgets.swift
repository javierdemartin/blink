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

import SwiftUI

////////////////////////////////////////////////////////////////////////////////
/// Available widgets shown in the top right side of the view
////////////////////////////////////////////////////////////////////////////////

/**
 `LongProcessWidget.asParameter` is needed to bind a protocol on `LongProcessWidgetView`.
 Currently on Swift, `Binding<LongProcessWidget>` & `Binding<ProtocolImplementation>` are different even when
 something conforms to the protocol. This is a current Swift limitation.
 
 One workaround is to add the `asParameter` computed property.
 
 https://developer.apple.com/forums/thread/652064
 */
protocol LongProcessWidget {
  /// SFSymbol name for the image to show
  var imageName: String { get }
  
  var accesibilityLabel: String { get }
  var title: String { get }
  var subtitle: String { get }
  
  var asParameter: LongProcessWidget {get set}
}

extension LongProcessWidget {
    var asParameter: LongProcessWidget {
        get {self as LongProcessWidget }
        set {self = newValue as! Self}
    }
}

// MARK: - Lock Screen Widget

enum LockScren: LongProcessWidget {
  case lock
  case unlock
  
  var imageName: String {
    switch self {
    case .lock:
      return "lock.fill"
    case .unlock:
      return "lock.slash.fill"
    }
  }
  
  var accesibilityLabel: String {
    switch self {
    case .lock:
      return "Lock screen"
    case .unlock:
      return "Unlock screen"
    }
  }
  
  var title: String {
    switch self {
    case .lock:
      return "Lock status"
    case .unlock:
      return "Lock status"
    }
  }
  
  var subtitle: String {
    switch self {
    case .lock:
      return "Locked"
    case .unlock:
      return "Unlocked"
    }
  }
}

// MARK: - Screen Layout Widget

enum ScreenLayoutWidget: Int, LongProcessWidget {
  case defaultMode = 0
  case fill
  case cover
  case safeFit
  
  var imageName: String {
    switch self {
    case .defaultMode:
      return "rectangle.and.arrow.up.right.and.arrow.down.left"
    case .fill:
      return "rectangle.fill"
    case .cover:
      return "rectangle.fill.badge.plus"
    case .safeFit:
      return "rectangle.inset.fill"
    }
  }
  
  var accesibilityLabel: String {
    switch self {
    case .defaultMode:
      return "Default Mode"
    case .fill:
      return "Fill"
    case .cover:
      return "Cover"
    case .safeFit:
      return "Safe fit"
    }
  }
  
  var title: String {
    switch self {
    case .defaultMode:
      return "Default Mode"
    case .fill:
      return "Fill"
    case .cover:
      return "Cover"
    case .safeFit:
      return "Safe fit"
    }
  }
  
  var subtitle: String {
    switch self {
    case .defaultMode:
      return "Default Mode"
    case .fill:
      return "Fill"
    case .cover:
      return "Cover"
    case .safeFit:
      return "Safe fit"
    }
  }
}

// MARK: - Geo Status

enum GeoStatus: LongProcessWidget {
  
  case tracking
  case stopped
  
  var imageName: String {
    switch self {
    case .tracking:
      return "location.viewfinder"
    case .stopped:
      return "location.viewfinder"
    }
  }
  
  var accesibilityLabel: String {
    switch self {
    case .tracking:
      return "Geo lock command enabled"
    case .stopped:
      return "GPS tracking stopped"
    }
  }
  
  var title: String {
    switch self {
    case .tracking:
      return "Geo command"
    case .stopped:
      return "Geo command"
    }
  }
  
  var subtitle: String {
    switch self {
    case .tracking:
      return "Tracking"
    case .stopped:
      return "Stopped"
    }
  }
}
