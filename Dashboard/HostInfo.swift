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

/**
 Vertical widget on the bottom-left that shows information of the current `TerminalController` shown on screen.
 */
struct HostInfoView: View {
  
  // TODO: Update info with the new wrapper on terminal's change
  @State var hostname: String = "javier.blink.zone"
  @State var user: String = "javier"
  // TODO: Get session's data
  @State var lifetime: Date = Date()
  
  @State private var isPresentingDocumentPicker = false
  
  @State private var isPresentingPortForwardConfig = false
  
  var body: some View {
    VStack(alignment: .leading) {
      
      Menu(content: {
        Group {
          // TODO: Integrate with the key agent
          Label("Manage Agent", systemImage: "key")
        }
        
        Divider()
        
        Group {
          Button(action: {
            isPresentingDocumentPicker.toggle()
          }) {
            Label("Upload File", systemImage: "folder")
              .foregroundColor(BKDashboardColor.secondary)
          }
          // TODO: How to pre-select all of the possible files?
        }
        
        Divider()
        
        Group {
          Label("Manage Ports", systemImage: "bolt.horizontal.fill")
          
          Label("Upload File", systemImage: "terminal.fill")
        }
        
        Divider()
        
        Group {
          Label("New Connection", systemImage: "network")
        }
        
      }, label: {
        Button(action: {
          
        }) {
          HStack {
            Image(systemName: "network")
              .modifier(ImageStyle())
            
            Text(hostname).bold()
          }
          .modifier(HeaderElement())
        }
        .modifier(HeaderElement())
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(BKDashboardColor.textColor)
      })
      
      HStack {
        Image(systemName: "person")
          .modifier(ImageStyle())
        
        Text(user)
      }
      .modifier(HeaderElement())
      .foregroundColor(BKDashboardColor.secondText)
      
      HStack {
        Image(systemName: "key")
          .modifier(ImageStyle())
        
        Text("Key Agent")
      }
      .modifier(HeaderElement())
      .foregroundColor(BKDashboardColor.secondText)
      
      Button(action: {
        isPresentingPortForwardConfig.toggle()
      }) {
        HStack {
          Image(systemName: "bolt.horizontal.fill")
            .modifier(ImageStyle())
          // TODO: Integrate with the currently active tunnels
          Text("2050")
        }
        .foregroundColor(BKDashboardColor.secondText)
      }
      .buttonStyle(PlainButtonStyle())
      .sheet(isPresented: $isPresentingPortForwardConfig) { PortForwardingRulesView() }
      
      HStack {
        Image(systemName: "clock")
          .modifier(ImageStyle())
        
        Text("5 hours")
      }
      .foregroundColor(BKDashboardColor.secondText)
    }
    .modifier(Module())
    .modifier(ModulePadding())
    .fileImporter(isPresented: $isPresentingDocumentPicker, allowedContentTypes: [], onCompletion: { result in
      
      switch result {
      
      case .success(let fileUrl):
        // TODO: Attach to the wrapper and upload the file to the host
        print(fileUrl)
      case .failure(let er):
        print(er)
      }
    })
  }
}
