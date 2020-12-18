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
import Foundation

/**
 View modifier methods return opaque views (`some View`) rather than complex generic types. This doesn't lets us use the following
 syntax to use generics.
 
 class SwiftUIHostingController<V: View>: UIHostingController<V>

 The following links help with understanding this behavior:
  - https://stackoverflow.com/a/57134853/4296481
  - https://www.hackingwithswift.com/books/ios-swiftui/why-does-swiftui-use-some-view-for-its-view-type
 
 For the meantime use `AnyView`.
 */
class SwiftUIHostingController<V: View>: UIHostingController<AnyView> {

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  /**
   Receive a common `EnvironmentObject` to set it to the given `rootView`
   */
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
  /// Close specified `TerminalController` identified by its `UUID`
  case closeTab(id: UUID)
  case enableGeoLock
  case stopGeoLock
  case geoLock
  case iterateScreenMode
  case pasteOnTerm(text: String)
  /// Tapped on a terminal and animates the transition to that TerminalController
  case moveTo(term: UUID)
  /// Reordered tabs
  case reorderedTerms(current: UUID, ids: [BrainSessionData])
  
  case lockLayout
  case unlockLayout
}

/**
 Required to answer back to some `BKDashboardAction`
 */
enum BKDashboardConsequence {
  case geoLockStatus(status: String)
  case screenMode(status: ScreenLayoutWidget)
  case setActiveTerm(byId: UUID)
  case receivedBell(on: UUID)
  case changedTermTitle(on: UUID, title: String)
}

/**
 Used to present a `String` description of the currently selected mode
 */
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

struct BKDashboardColor {
  static var backgroundColor: Color = Color(hex: "272C36")
  static var overlay: Color = Color.white.opacity(0.8)
  static var carrousel: Color = Color(hex: "EBEBF5").opacity(0.3)
  static var protocolColor: Color = Color(hex: "EBEBF5").opacity(0.6)
  static var textColor: Color = Color.white
  static var tint: Color = Color("BlinkColor")
  static var bleh: Color = Color(hex: "8E8E93")
  static var pillColor: Color = Color(hex: "1C1C1E")
  static var module: Color = Color(hex: "3A3A3C") //.opacity(0.8)
  static var clear: Color = Color(UIColor.clear)
  static var lightText: Color = Color(UIColor.lightText)
  static var light: Color = Color(UIColor.label).opacity(0.2)
  static var secondary: Color = Color(UIColor.secondaryLabel)
  static var secondText: Color = Color(hex: "EBEBF5") //Color(UIColor.secondaryLabel)
  static var longProcess: Color = Color(UIColor.secondarySystemFill).opacity(0.32)
  
  //  static var backgroundColor: Color = Color(hex: "272C36")
  //  static var overlay: Color = Color.white.opacity(0.8)
  //  static var carrousel: Color = Color(UIColor.tertiaryLabel).opacity(0.3) // Color(hex: "EBEBF5").opacity(0.3)
  //
  //  static var textColor: Color = Color(UIColor.label) // Color.white
  //  static var secondText: Color = Color(UIColor.secondaryLabel)
  //  static var tint: Color = Color("BlinkColor")
  //  static var bleh: Color = Color(hex: "8E8E93")
  //  static var pillColor: Color = Color(UIColor.systemBackground) // Color(hex: "1C1C1E")
  //  static var module: Color = Color(UIColor.tertiarySystemBackground).opacity(0.8) // Color(hex: "3A3A3C").opacity(0.8)
  //  static var longProcess: Color = Color(UIColor.secondarySystemFill).opacity(0.32)
  //  static var clear: Color = Color(UIColor.clear)
  //  static var lightText: Color = Color(UIColor.secondaryLabel).opacity(0.6) //  Color(UIColor.lightText)
  //  static var light: Color = Color(UIColor.label).opacity(0.2)
  //  static var secondary: Color = Color(UIColor.secondaryLabel)
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

struct BKDashboard: View {
  
  @EnvironmentObject var settings: DashboardBrain
  
  var body: some View {
    
    VStack(alignment: .leading) {
      
      HostInfoView()
      
      PermanentBottomLeft(urls: $settings.urls, action: $settings.dashboardAction)
    }.frame(maxWidth: .infinity, maxHeight: .infinity)
    
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
            
            // TODO: Add snippets
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



// MARK: View Modifiers

struct PillButtonModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .background(EffectsView(material: UIBlurEffect(style: .systemUltraThinMaterial)))
      .foregroundColor(BKDashboardColor.textColor)
      .background(BKDashboardColor.pillColor)
      .cornerRadius(13.0)
      .buttonStyle(PlainButtonStyle())
      .modifier(ModulePadding())
  }
}

struct Module: ViewModifier {
  func body(content: Content) -> some View {
    content
      .background(BKDashboardColor.module)
      .cornerRadius(13.0)
    
  }
}

struct LongProcessModule: ViewModifier {
  func body(content: Content) -> some View {
    content
      .background(EffectsView(material: UIBlurEffect(style: .systemUltraThinMaterialDark)))
      .background(BKDashboardColor.longProcess)
      
      .cornerRadius(13.0)
    
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
