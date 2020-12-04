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
import UniformTypeIdentifiers

/**
 Overlapping view on top of a `TabView` that displays session's data
 */
struct CarrouselData: View {
  
  /// Protocol being used
  @State var proto: String = "ssh"
  @State var host: String = "javier.blink.zone"
  @State var process: String = "node server.js -p 3000"
  
  @Binding var data: BrainSessionData
  
  var body: some View {
    VStack(alignment: .leading) {
      
      HStack {
        ProtocolSession(networkProtocol: $proto)
        Text(host)
          .font(.footnote)
          .foregroundColor(BKDashboardColor.lightText)
        
        Spacer()
      }
      
//      Text(process)
      Text(data.title!)
        .foregroundColor(BKDashboardColor.textColor)
        .lineLimit(1)
        .padding(.vertical, 3)
    }
    .padding(6)
    .background(BKDashboardColor.carrousel)
  }
}

/**
 Matches `TabView` sizing but it's an empty view that allows tapping on it to open a new `TerminalController`
 */
struct NewSessionView: View {
  
  var action = PassthroughSubject<BKDashboardAction, Never>()
  
  var body: some View {
    
    HStack(alignment: .center) {
      
      Spacer()
      
      Image(systemName: "plus")
        .resizable()
        .foregroundColor(BKDashboardColor.light)
        .frame(width: 30, height: 30, alignment: .center)
      Spacer()
      
    }
    .frame(width: 188, height: 138)
    .overlay(
      RoundedRectangle(cornerRadius: 13.0)
        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
        .background(BKDashboardColor.carrousel)
    )
    .background(BKDashboardColor.backgroundColor)
    .cornerRadius(13.0)
    .modifier(ModulePadding())
    .onTapGesture(perform: {
      action.send(.newTab)
    })
  }
}

/**
 Represents information of a terminal's tab.
 */
struct TabView: View {
  
  @Binding var activeSession: UUID?
  
  @State var bellRing: Bool = true
  
  var isActive: Bool {
    get {
      return uuid.id == (activeSession ?? UUID())
    }
  }
  
  /**
   
   */
  var action = PassthroughSubject<BKDashboardAction, Never>()
  
//  @Binding var uuid: UUID
  @Binding var uuid: BrainSessionData
  
  var body: some View {
    
    GeometryReader { g in
      
      VStack(alignment: .leading) {
        
        if bellRing {
          HStack {
            
            Button(action: {
              action.send(.closeTab(id: uuid.id))
            }) {
              Image(systemName: "multiply")
                .foregroundColor(BKDashboardColor.lightText)
                .padding(6)
            }
            
            Spacer()
            
            Image(systemName: "bell.badge")
              .foregroundColor(.red)
              .padding(6)
          }
        }
        
        Spacer()
        
        ZStack(alignment: .bottom) {
          CarrouselData(data: $uuid)
        }
        .frame(height: g.size.height * 0.35)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 13)) // clip corners
    
    .overlay(
      RoundedRectangle(cornerRadius: 13)
        .stroke(isActive ? BKDashboardColor.textColor : BKDashboardColor.clear, lineWidth: 2)
    )
    .background(
      RoundedRectangle(cornerRadius:13).fill(BKDashboardColor.backgroundColor)
    )
    .frame(width: 188, height: 138)
    .cornerRadius(13.0)
    .modifier(ModulePadding())
    .clipped(antialiased: true)
  }
}

/**
 Horizontal ScrollView containing the available terminals.
 */
struct TerminalsCarrousel: View {
  
  @EnvironmentObject var data: DashboardBrain
  @Namespace var nameSpace
  
  /**
   Default horizontal, Switches between tab overview.
   */
  @State var columns = [GridItem(.flexible(minimum: 250), spacing: 10)]
  
  @ObservedObject var dragStatus = SelectionStore()
  
  @State private var currentAmount: CGFloat = 0
  @State private var finalAmount: CGFloat = 1
  
  var body: some View {
    
    ZStack {
      
      if columns.count > 1 {
        EffectsView(material: UIBlurEffect(style: .systemMaterial))
      }
      
      ScrollView(.horizontal, showsIndicators: false) {
        
        VStack {
          
//          HStack {
          LazyHGrid(rows: columns, alignment: .center, spacing: 20) {
            
            ForEach(0..<data.activeTerminalControllers.count, id: \.self) { term in
              TabView(activeSession: $data.activeSession,
                      action: self.data.dashboardAction,
                      uuid: $data.activeTerminalControllers[term])
                .matchedGeometryEffect(id: data.activeTerminalControllers[term].id, in: nameSpace)
                
                .onTapGesture {
                  data.dashboardAction.send(.moveTo(term: data.activeTerminalControllers[term].id))
                }
                .clipShape(RoundedRectangle(cornerRadius: 13)) // clip corners
                .overlay(
                  RoundedRectangle(cornerRadius:13).fill((dragStatus.dragging == data.activeTerminalControllers[term].id && dragStatus.isInside) ? BKDashboardColor.carrousel : Color.clear)
                  
                )
                .onDrag {
                  self.dragStatus.dragging = data.activeTerminalControllers[term].id
                  return NSItemProvider(object: String(data.activeTerminalControllers[term].id.uuidString) as NSString)
                }
                .onDrop(of: [UTType.text], delegate: DragRelocateDelegate(item: data.activeTerminalControllers[term].id, listData: $data.activeTerminalControllers, current: $dragStatus.dragging, isInside: $dragStatus.isInside, finished: { id in
                  dragStatus.dragging = nil
                  data.dashboardAction.send(.reorderedTerms(current: id, ids: data.activeTerminalControllers))
                }))
              
            }
            
            NewSessionView(action: self.data.dashboardAction)
          }
          /**
           TODO: This is a WIP, do a Pinch gesture on the `"+"` (NewSession) to switch between the Terminals carrousel and a square grid like
           in Safari when previewing all of the open tabs. It works but not as performant with a lot of tabs open due to LazyGrids. Maybe it's better not to implement this and stick to a simple HStack adn no square grid.
           
           The pinch gesture switches the LazyGrid layout filling the whole screen.
           
           */
          .gesture(
            MagnificationGesture()
              .onEnded { amount in
                columns = Array(repeating: GridItem(.flexible(minimum: 250), spacing: 10), count: 4)
              })
          .animation(.default)
        }
      }
    }
    .onReceive(data.dashboardConsecuence, perform: { action in
      switch action {
      
      case .setActiveTerm(byId: let uuid):
        data.activeSession = uuid
        
      default: break
      }
    })
  }
}

/**
 Handle the reordering of `TerminalController`.
 */
struct DragRelocateDelegate: DropDelegate {
  /// Current terminal identifier that has started a Drag operation
  let item: UUID
//  @Binding var listData: [UUID]
  @Binding var listData: [BrainSessionData]
  @Binding var current: UUID?
  @Binding var isInside: Bool
  
  /// Notify when the operation has finished to deselect the highlighted cell
  var finished: (_: UUID) -> ()
  
  func dropEntered(info: DropInfo) {
    isInside = true
    
    if item != current {
      let from = listData.firstIndex(where: { $0.id == current! })!
      let to = listData.firstIndex(where: { $0.id == item })!
      if listData[to].id != current! {
        listData.move(fromOffsets: IndexSet(integer: from),
                      toOffset: to > from ? to + 1 : to)
      }
    }
  }
  
  func dropUpdated(info: DropInfo) -> DropProposal? {
    return DropProposal(operation: .move)
  }
  
  /**
   A valid drop operation has exited the modified view.
   */
  func dropExited(info: DropInfo) {
    isInside = false
  }
  
  func performDrop(info: DropInfo) -> Bool {
    
    finished(current!)
    self.current = nil
    
    return true
  }
}

final class SelectionStore: ObservableObject {
  
  @Published var dragging: UUID? = nil {
    didSet {
      print("Selection changed to \(String(describing: dragging))")
      
      if dragging == nil {
        
      }
    }
  }
  
  /**
   Set in the `DropDelegate` methods. If `true` the dragged Terminal window is correctly positioned
   to be dropped. If `false` the dragged Terminal window is being dropped outside and the overlayed color
   will be disabled.
   */
  @Published var isInside: Bool = false
}
