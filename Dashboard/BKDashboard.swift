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
import Foundation

class SwiftUIHostingController: UIHostingController<AnyView> {
  required init?(coder: NSCoder) {
    
    super.init(coder: coder)
  }
  
  init(rootView: AnyView, environmentSettings: DashboardBrain) {
    let listView = rootView.environmentObject(environmentSettings)
    super.init(rootView: AnyView(listView))
  }
  
  override init(rootView: AnyView) {
    
    let listView = rootView.environmentObject(DashboardBrain())
    super.init(rootView: AnyView(listView))
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
}

/**
 Associated actions the Dashboard can send back to `SpaceController`
 */
enum BKDashboardAction {
  case newTab
  case enableGeoLock
  case stopGeoLock
  case geoLock
  case iterateScreenMode
  case pasteOnTerm(text: String)
  /// Tapped on a terminal and animates the transition to that TerminalControlled
  case moveTo(term: UUID)
  /// Reordered tabs
  case reorderedTerms(current: UUID, ids: [UUID])
}

enum BKDashboardConsequence {
  case geoLockStatus(status: String)
  case screenMode(status: String)
  case setActiveTerm(byId: UUID)
}

enum ScreenAppearanceTranslator: Int {
  case defaultMode = 0
  case fill = 1
  case cover = 2
  case safeFit = 3
  
  var description: String {
    switch self {
    
    case .defaultMode:
      return "Default"
    case .fill:
      return "Fill"
    case .cover:
      return "Cover"
    case .safeFit:
      return "Fit"
    }
  }
}

enum FileOperation: String {
  case download = "arrow.down"
  case upload = "arrow.up"
}

struct ProgressBar: View {
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
      
      HStack(alignment: .center) {
        Text("\(pendingOperations)")
          .frame(width: 15, height: 15, alignment: .center)
          .clipped()
          .offset(x: 10)
        
        Image(systemName: fileOperation.rawValue)
          .resizable()
          .frame(width: 15, height: 15, alignment: .center)
          .clipped()
      }
      .offset(x: -7.5)
      
    }
    .foregroundColor(pendingOperations == 0 ? .gray: BKDashboardColor.tint)
  }
}

struct BKDashboardColor {
  //  static var backgroundColor: Color = Color(hex: "272C36")
  //  static var overlay: Color = Color.white.opacity(0.8)
  //  static var carrousel: Color = Color(hex: "EBEBF5").opacity(0.3)
  //  static var protocolColor: Color = Color(hex: "EBEBF5").opacity(0.6)
  //  static var textColor: Color = Color.white
  //  static var tint: Color = Color("BlinkColor")
  //  static var bleh: Color = Color(hex: "8E8E93")
  //  static var pillColor: Color = Color(hex: "1C1C1E")
  //  static var module: Color = Color(hex: "3A3A3C").opacity(0.8)
  //  static var clear: Color = Color(UIColor.clear)
  //  static var lightText: Color = Color(UIColor.lightText)
  //  static var light: Color = Color(UIColor.label).opacity(0.2)
  //  static var secondary: Color = Color(UIColor.secondaryLabel)
  
  static var backgroundColor: Color = Color(hex: "272C36")
  static var overlay: Color = Color.white.opacity(0.8)
  static var carrousel: Color = Color(UIColor.tertiaryLabel).opacity(0.3) // Color(hex: "EBEBF5").opacity(0.3)
  
  static var textColor: Color = Color(UIColor.label) // Color.white
  static var secondText: Color = Color(UIColor.secondaryLabel)
  static var tint: Color = Color("BlinkColor")
  static var bleh: Color = Color(hex: "8E8E93")
  static var pillColor: Color = Color(UIColor.systemBackground) // Color(hex: "1C1C1E")
  static var module: Color = Color(UIColor.tertiarySystemBackground).opacity(0.8) // Color(hex: "3A3A3C").opacity(0.8)
  static var longProcess: Color = Color(UIColor.secondarySystemFill).opacity(0.32)
  static var clear: Color = Color(UIColor.clear)
  static var lightText: Color = Color(UIColor.secondaryLabel).opacity(0.6) //  Color(UIColor.lightText)
  static var light: Color = Color(UIColor.label).opacity(0.2)
  static var secondary: Color = Color(UIColor.secondaryLabel)
}

/**
 Represents information of a terminal's tab.
 */
struct TabView: View {
  
  //  @EnvironmentObject var data: DashboardBrain
  @Binding var activeSession: UUID?
  
  //  var d: GridData
  
  @State var bellRing: Bool = true
  
  var isActive: Bool {
    get {
      return uuid == (activeSession ?? UUID())
    }
  }
  
  @Binding var uuid: UUID
  
  var body: some View {
    
    GeometryReader { g in
      
      VStack(alignment: .leading) {
        
        if bellRing {
          HStack {
            Spacer()
            
            Image(systemName: "bell.badge")
              .foregroundColor(.red)
              .padding(6)
          }
        }
        
        Spacer()
        
        ZStack(alignment: .bottom) {
          CarrouselData()
        }
        .frame(height: g.size.height * 0.35)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 13)) // clip corners
    
    .overlay(
      RoundedRectangle(cornerRadius: 13)
        .stroke(isActive ? BKDashboardColor.textColor : BKDashboardColor.clear, lineWidth: 2)
    )
    //    .background(BKDashboardColor.backgroundColor)
    .background(
      RoundedRectangle(cornerRadius:13).fill(BKDashboardColor.backgroundColor)
    )
    .frame(width: 188, height: 138)
    .cornerRadius(BKDashboardCornerRadius)
    .modifier(ModulePadding())
    .clipped(antialiased: true)
  }
}

final class SelectionStore: ObservableObject {
  @Published var dragging: UUID? = nil {
    didSet {
      print("Selection changed to \(dragging)")
      
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

/**
 Horizontal ScrollView containing the available terminals.
 */
struct TerminalsCarrousel: View {
  
  @EnvironmentObject var data: DashboardBrain
  
  var columns: [GridItem] = [GridItem(.flexible())]
  
  @ObservedObject var dragStatus = SelectionStore()
  
  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      
      HStack {
        
        ForEach(0..<data.numberOfActiveSessions.count, id: \.self) { term in
          TabView(activeSession: $data.activeSession,
                  uuid: $data.numberOfActiveSessions[term])
            .onTapGesture {
              data.dashboardAction.send(.moveTo(term: data.numberOfActiveSessions[term]))
            }
            .clipShape(RoundedRectangle(cornerRadius: 13)) // clip corners
            .overlay(
              RoundedRectangle(cornerRadius:13).fill((dragStatus.dragging == data.numberOfActiveSessions[term] && dragStatus.isInside) ? BKDashboardColor.carrousel : Color.clear)
              
            )
            .onDrag {
              self.dragStatus.dragging = data.numberOfActiveSessions[term]
              return NSItemProvider(object: String(data.numberOfActiveSessions[term].uuidString) as NSString)
            }
            .onDrop(of: [UTType.text], delegate: DragRelocateDelegate(item: data.numberOfActiveSessions[term], listData: $data.numberOfActiveSessions, current: $dragStatus.dragging, isInside: $dragStatus.isInside, finished: { id in
              dragStatus.dragging = nil
              data.dashboardAction.send(.reorderedTerms(current: id, ids: data.numberOfActiveSessions))
            }))
        }
        
        NewSessionView(action: self.data.dashboardAction)
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

struct DragRelocateDelegate: DropDelegate {
  let item: UUID
  @Binding var listData: [UUID]
  @Binding var current: UUID?
  @Binding var isInside: Bool
  
  var finished: (_: UUID) -> ()
  
  func dropEntered(info: DropInfo) {
    isInside = true
    
    if item != current {
      let from = listData.firstIndex(of: current!)!
      let to = listData.firstIndex(of: item)!
      if listData[to] != current! {
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
  
  /**
   
   */
  func performDrop(info: DropInfo) -> Bool {
    
    finished(current!)
    self.current = nil
    
    return true
  }
}

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
  
  //  @Published var numberOfActiveSessions: [TermController] = []
  @Published var numberOfActiveSessions: [UUID] = []
  
  @Published var activeSession: UUID?
  
}

struct CarrouselData: View {
  
  @State var proto: String = "ssh"
  @State var host: String = "javier.blink.zone"
  @State var process: String = "node server.js -p 3000"
  
  var body: some View {
    VStack(alignment: .leading) {
      
      HStack {
        ProtocolSession(networkProtocol: $proto)
        Text(host)
          .font(.footnote)
          .foregroundColor(BKDashboardColor.lightText)
        
        Spacer()
      }
      
      Text(process)
        .foregroundColor(BKDashboardColor.textColor)
        .lineLimit(1)
        .padding(.vertical, 3)
    }
    .padding(6)
    .background(EffectsView(material: UIBlurEffect(style: .systemUltraThinMaterial)))
    .background(BKDashboardColor.carrousel)
  }
}

/**
 Mini-badge that displays the network protocol used in the connection
 */
struct ProtocolSession: View {
  
  @Binding var networkProtocol: String
  
  var body: some View {
    Text(networkProtocol)
      .font(.footnote)
      .foregroundColor(BKDashboardColor.pillColor)
      .padding(2)
      .background(BKDashboardColor.lightText)
      .cornerRadius(6)
  }
}

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
      RoundedRectangle(cornerRadius: BKDashboardCornerRadius)
        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
        .background(BKDashboardColor.carrousel)
    )
    .background(BKDashboardColor.backgroundColor)
    .cornerRadius(BKDashboardCornerRadius)
    .modifier(ModulePadding())
    .onTapGesture(perform: {
      action.send(.newTab)
    })
  }
}

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
            ProgressBar(progress: self.$progressValue, pendingOperations: settings.downloads.count, fileOperation: .download)
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
        ProgressBar(progress: self.$progressValue, pendingOperations: settings.downloads.count, fileOperation: .upload)
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

struct BKDashboard: View {
  
  @EnvironmentObject var settings: DashboardBrain
  
  var body: some View {
    
    VStack(alignment: .leading) {
      
      HostInfoView()
      
      PermanentBottomLeft(urls: $settings.urls, action: $settings.dashboardAction)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    
  }
}

struct ScrollableActions: View {
  
  @State var address: String = "80:localhost:1234"
  
  @State var validatedURL: URL?
  
  var body: some View {
    HStack {
      
      Menu(content: {
        
        if let validUrl = validatedURL, let port = validUrl.port {
          Label("Forward Port \(port)", systemImage: "bolt.horizontal")
        }
        
        Divider()
        
        Label("Google", systemImage: "magnifyingglass")
        
        if let validUrl = validatedURL {
          Button(action: {
            blink_openurl(validUrl)
          }) {
            Label("Open in Safari", systemImage: "safari")
          }
        }
        
        Label("Copy", systemImage: "doc.on.doc")
        
      }, label: {
        Button(action: {
          
        }) {
          ZStack {
            Circle()
              .clipShape(Circle())
              .opacity(0.4)
              .modifier(ImageStyle())
              .foregroundColor(BKDashboardColor.bleh)
            
            Image(systemName: "bolt.horizontal")
              .foregroundColor(Color.black)
            
            //            Image(systemName: "bolt.horizontal.fill")
            //              .renderingMode(.template)
            //              .foregroundColor(Color(UIColor.blinkTint))
          }
          .modifier(ModulePadding())
        }.buttonStyle(PlainButtonStyle())
      })
      
      TextField("Address", text: $address)
        .frame(width: 160)
        .modifier(ModulePadding())
        .modifier(PillButtonModifier())
        .foregroundColor(BKDashboardColor.textColor)
        .onReceive(address.publisher, perform: { value in
          print(address)
          
          if let correctUrl = URL(string: address) {
            validatedURL = correctUrl
          }
          
        })
    }
    .modifier(Module())
    .modifier(ModulePadding())
  }
}

struct HostInfoView: View {
  
  @State var hostname: String = "javier.blink.zone"
  @State var user: String = "javier"
  @State var lifetime: Date = Date()
  @State private var showDocPicker = false
  @State private var isFlipped = false
  
  
  var body: some View {
    VStack(alignment: .leading) {
      
      Menu(content: {
        Group {
          Label("Manage Agent", systemImage: "key")
        }
        
        Divider()
        
        Group {
          Button(action: {
            showDocPicker.toggle()
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
        isFlipped.toggle()
      }) {
        HStack {
          Image(systemName: "bolt.horizontal.fill")
            .modifier(ImageStyle())
          
          Text("2050")
        }
        .foregroundColor(BKDashboardColor.secondText)
      }
      .buttonStyle(PlainButtonStyle())
//      .modifier(HeaderElement())
      .sheet(isPresented: $isFlipped) { PortForwardingRulesView() }
      
      HStack {
        Image(systemName: "clock")
          .modifier(ImageStyle())
        
        Text("5 hours")
      }
      //            .modifier(HeaderElement())
      .foregroundColor(BKDashboardColor.secondText)
    }
    .modifier(Module())
    .modifier(ModulePadding())
    .fileImporter(isPresented: $showDocPicker, allowedContentTypes: [.pdf, .text, .plainText], onCompletion: { result in
      
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

struct PermanentBottomLeft: View {
  
  @Binding var urls: [String]
  
  @Binding var action: PassthroughSubject<BKDashboardAction, Never>
  
  var body: some View {
    
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        HStack {
          Button(action: {
            
          }) {
            Text("Copy")
              .lineLimit(1)
              // Force the text to take all the horizontal space it needs
              .fixedSize(horizontal: true, vertical: false)
              .modifier(ModulePadding())
          }
          .modifier(PillButtonModifier())
          
          
          Menu(content: {
            
            // TODO: Add contents of pasteboard for recent values
            
            Divider()
            
            ForEach(urls, id: \.self) { url in
              
              Button(action: {
                action.send(.pasteOnTerm(text: url))
              }, label: {
                Text(url)
              })
            }
            
          }, label: {
            Button(action: {
              
            }) {
              Text("Paste")
                .lineLimit(1)
                // Force the text to take all the horizontal space it needs
                .fixedSize(horizontal: true, vertical: false)
                .modifier(ModulePadding())
            }
            .modifier(PillButtonModifier())
          })
          
          
          
        }
        .modifier(Module())
        .modifier(ModulePadding())
        
        HStack {
          
          ForEach(urls, id: \.self) { url in
            ScrollableActions(address: url)
          }
          
        }
      }
    }
  }
}

struct PillButtonModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .background(EffectsView(material: UIBlurEffect(style: .systemUltraThinMaterial)))
      .foregroundColor(BKDashboardColor.textColor)
      .background(BKDashboardColor.pillColor)
      .cornerRadius(BKDashboardCornerRadius)
      .buttonStyle(PlainButtonStyle())
      .modifier(ModulePadding())
  }
}

// MARK: View Modifiers

let BKDashboardCornerRadius: CGFloat = 13.0

struct Module: ViewModifier {
  func body(content: Content) -> some View {
    content
      .background(EffectsView(material: UIBlurEffect(style: .systemUltraThinMaterial)))
      
//      .background(Rectangle().fill(BKDashboardColor.module)) //.blur(radius: 4))

      
      .background(BKDashboardColor.module)
//      .blur(radius: 4)
      
      .cornerRadius(BKDashboardCornerRadius)
    
  }
}

struct LongProcessModule: ViewModifier {
  func body(content: Content) -> some View {
    content
//      .background(EffectsView(material: UIBlurEffect(style: .systemMaterial)))
      .background(BKDashboardColor.longProcess)
      
      .cornerRadius(BKDashboardCornerRadius)
    
  }
}

struct ModulePadding: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(.horizontal, 9)
      .padding(.vertical, 12)
  }
}

struct HeaderElement: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(.horizontal, 3)
    //          .foregroundColor(BKDashboardColor.textColor)
  }
}

struct ImageStyle: ViewModifier {
  func body(content: Content) -> some View {
    content.frame(width: 34, height: 34, alignment: .center)
  }
}

struct EffectsView: UIViewRepresentable {
  var material: UIBlurEffect

  /// https://pspdfkit.com/blog/2020/blur-effect-materials-on-ios/
  func makeUIView(context: Context) -> some UIView {
    let visualEffectView = UIVisualEffectView()


    visualEffectView.effect = material

    let vibrancyEffect = UIVibrancyEffect(blurEffect: material, style: .fill)

    // Add a new `UIVibrancyEffectView` to the `contentView` of the earlier added `UIVisualEffectView`.
    let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
    vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false

    visualEffectView.contentView.addSubview(vibrancyEffectView)

    return visualEffectView
  }


  func updateUIView(_ uiView: UIViewType, context: Context) {
    (uiView as! UIVisualEffectView).effect = material
  }
}
