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
import Combine

struct DownloadProcessBarView: View {
  @Binding var progress: Float
  
  @State var pendingOperations: Int
  
  @State var fileOperation: FileOperation
  
  var body: some View {
    ZStack {
      Circle()
        .stroke(lineWidth: 5.0)
        .opacity(0.3)
      
      Circle()
        .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
        .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
        .rotationEffect(Angle(degrees: 270.0))
        .animation(.linear)
      
      HStack(alignment: .top) {
        Text("\(pendingOperations)")
          .frame(width: 15, height: 15, alignment: .center)
          .clipped()
          .offset(x: 10)
        
        Image(systemName: fileOperation.rawValue)
          .resizable()
          .frame(width: 8, height: 8, alignment: .center)
          .clipped()
      }
      .offset(x: -7.5)
    }
    .foregroundColor(pendingOperations == 0 ? .gray: BKDashboardColor.tint)
  }
}

/**
 Widget shown on the top-right corner that displays common actions or long running processes that are agnostic to any session.
 */
struct LongProcessesView: View {
  
  var cancellableBag: Set<AnyCancellable> = []
  
  @EnvironmentObject var settings: DashboardBrain
  
  @State var geoLockMessage: String?
  
  @State var progressValue: Float = 0.0
  
  @State var screenMode: String?
  
  @State var isImporting: Bool = false
  
  var body: some View {
    
    HStack {
      Menu(content: {
        
        if settings.downloads.isEmpty {
          Text("No recent downloads")
        } else {
          ForEach(settings.downloads, id: \.self) { file in
            Text(file)
          }
        }
        
      }, label: {
        Button(action: {
          
        }) {
          ZStack {
            DownloadProcessBarView(progress: self.$progressValue, pendingOperations: settings.downloads.count, fileOperation: .download)
              .modifier(ImageStyle())
          }
          .padding()
          .modifier(LongProcessModule())
        }
        .buttonStyle(PlainButtonStyle())
      })
      
      Button {
        isImporting.toggle()
      } label: {
        DownloadProcessBarView(progress: self.$progressValue, pendingOperations: settings.downloads.count, fileOperation: .upload)
      }
      .modifier(ImageStyle())
      .padding()
      .modifier(LongProcessModule())
      // TODO: How to pre-select all of the possible files?
      .fileImporter(isPresented: $isImporting, allowedContentTypes: [.pdf, .text, .plainText], onCompletion: { result in
        
        switch result {
        
        case .success(let fileUrl):
          // TODO: Attach to the wrapper and upload the file to the host
          print(fileUrl)
        case .failure(let er):
          print(er)
        }
      })
      
      Button {
        withAnimation {
          
          settings.dashboardAction.send(.geoLock)
          dismissHUDAfterTime(completion: {
            geoLockMessage = nil
          })
        }
      } label: {
        ZStack {
          HStack {
            
            Image(systemName: "location.viewfinder")
              .modifier(ImageStyle())
              .padding()
            
            if geoLockMessage != nil {
              VStack(alignment: .leading) {
                
                Text("Geo Persistence".uppercased())
                  .foregroundColor(BKDashboardColor.textColor)
                  .fontWeight(.bold)
                  .font(.system(.caption, design: .rounded))
                
                Text(geoLockMessage!)
                  .bold()
                  .foregroundColor(BKDashboardColor.textColor)
                  .padding(.trailing)
                
                
              }.padding(.trailing)
            }
          }
        }
        .foregroundColor((GeoManager.shared().traking) ? BKDashboardColor.tint : .gray)
      }
      .modifier(LongProcessModule())
      .animation(.easeInOut)
      
      
      Button {
        withAnimation {
          settings.dashboardAction.send(.iterateScreenMode)
          dismissHUDAfterTime(completion: {
            screenMode = nil
          })
        }
        
      } label: {
        ZStack {
          HStack(alignment: .center) {
            Image(systemName: "rectangle.and.arrow.up.right.and.arrow.down.left")
              .modifier(ImageStyle())
              .padding()
            
            if screenMode != nil {
              VStack(alignment: .leading) {
                Text("Screen Layout".uppercased())
                  .foregroundColor(BKDashboardColor.textColor)
                  .fontWeight(.bold)
                  .font(.system(.caption, design: .rounded))
                
                Text(screenMode!)
                  .bold()
                  .foregroundColor(BKDashboardColor.textColor)
                  .padding(.trailing)
                
              }.padding(.trailing)
            }
          }
        }
      }
      .modifier(LongProcessModule())
      .animation(.easeInOut)
      
    }.modifier(ModulePadding())
    .onReceive(settings.dashboardConsecuence, perform: { a in
      switch a {
      
      case .geoLockStatus(status: let status):
        geoLockMessage = status
        
      case .screenMode(status: let status):
        screenMode = status
        
      default: break
      }
    })
    .animation(.linear)
  }
  
  func dismissAnimation() {
    screenMode = nil
  }
  
  // TODO: Make it cancel when multiple taps are performed
  func dismissHUDAfterTime(completion: @escaping(() -> Void)) {
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      completion()
    }
  }
}
