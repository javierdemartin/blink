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

struct CommunityBlockerView: View {
  var body: some View {
    VStack(alignment: .leading) {
      Text("Upgrade Blink!")
        .bold()
        .font(.system(size: 40, design: .rounded)).padding(.bottom, 30)
        .foregroundColor(Color(UIColor.label))
      Text("Thank you for using the community version of Blink!")
        .padding(.bottom)
        .font(.system(size: 30, design: .rounded))
        .foregroundColor(Color(UIColor.label))
      Text("Shake the device or wait a minute to receive more time or upgrade to the full version.")
        .padding(.bottom, 30)
        .font(.system(size: 30, design: .rounded))
        .foregroundColor(Color(UIColor.label))

      HStack(alignment: .center) {
        
        
        Button (action: {
          // TODO: Open subscription panel
            
        }, label: {
          Text("Let's go!")
            .padding()
            .font(.system(size: 30, design: .rounded))
            .foregroundColor(Color.primary)
        })
        .background(Color(UIColor.blinkTint))
        .cornerRadius(13.0)

      }
      
    }
  }
}
