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
}

enum BKDashboardConsequence {
  case geoLockStatus(status: String)
  case screenMode(status: String)
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
    .foregroundColor(pendingOperations == 0 ? .gray: Color("BlinkColor"))
  }
}

/**
 Horizontal ScrollView containing the available terminals.
 */
struct TerminalsCarrousel: View {
  
  @EnvironmentObject var data: DashboardBrain
  
  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        
        TabView(bellRing: true, data: _data)
        
        NewSessionView(action: self.data.dashboardAction)
      }
    }
  }
}

/**
 Represents information of a terminal's tab.
 */
struct TabView: View {
  
  @State var bellRing: Bool = true
  
  @EnvironmentObject var data: DashboardBrain
  
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
    .background(Color(hex: "272C36"))
    .frame(width: 188, height: 138)
    .cornerRadius(BKDashboardCornerRadius)
    .modifier(ModulePadding())
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
          .foregroundColor(Color(UIColor.lightText))
        
        Spacer()
      }
      
      Text(process)
        .foregroundColor(Color.white)
        .lineLimit(1)
        .padding(.vertical, 3)
    }
    .padding(6)
    .background(Color(hex: "EBEBF5").opacity(0.3))
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
      .foregroundColor(Color(hex: "1C1C1E"))
      .padding(2)
      .background(Color(hex: "EBEBF5").opacity(0.6))
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
            .foregroundColor(Color(UIColor.label).opacity(0.2))
            .frame(width: 30, height: 30, alignment: .center)
      Spacer()

    }
    .frame(width: 188, height: 138)
    .overlay(
      RoundedRectangle(cornerRadius: BKDashboardCornerRadius)
        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
        .background(Color(hex: "EBEBF5").opacity(0.3))
    )
    .background(Color(hex: "272C36"))
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
            .modifier(Module())
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
        .modifier(Module())
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
                    .foregroundColor(Color.white)
                    .fontWeight(.bold)
                    .font(.system(.caption, design: .rounded))
                  
                  Text(geoLockMessage!)
                    .bold()
                    .foregroundColor(Color.white)
                    .padding(.trailing)
                  
                    
                }.padding(.trailing)
              }
            }
          }
          .foregroundColor((GeoManager.shared().traking) ? Color("BlinkColor") : .gray)
        }
        .modifier(Module())
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
                    .foregroundColor(Color.white)
                    .fontWeight(.bold)
                    .font(.system(.caption, design: .rounded))
                  
                  Text(screenMode!)
                    .bold()
                    .foregroundColor(Color.white)
                    .padding(.trailing)
                    
                }.padding(.trailing)
              }
            }
          }
        }
        .modifier(Module())
        .animation(.easeInOut)
        
      }.modifier(ModulePadding())
      .onReceive(settings.dashboardConsecuence, perform: { a in
      switch a {
      
      case .geoLockStatus(status: let status):
        geoLockMessage = status
      
      case .screenMode(status: let status):
        screenMode = status
      }
    })
    .animation(.linear)
  }
  
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
              .foregroundColor(Color(hex: "8E8E93"))
              
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
        .foregroundColor(Color.white)
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
                      .foregroundColor(Color(UIColor.secondaryLabel))
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
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(Color.white)
            })
            
            HStack {
                Image(systemName: "person")
                  .modifier(ImageStyle())
                  
              Text(user)
                
            }.modifier(HeaderElement())
            
            HStack {
                Image(systemName: "key")
                  .modifier(ImageStyle())
                  
                Text("Key Agent")
                  
                  
            }.modifier(HeaderElement())
            
          Button(action: {
            isFlipped.toggle()
          }) {
            HStack {
                Image(systemName: "bolt.horizontal.fill")
                  .modifier(ImageStyle())
              
                Text("2050")
              }
          }
          .buttonStyle(PlainButtonStyle())
          .modifier(HeaderElement())
//          .sheet(isPresented: $isFlipped) { PortForwardRule(presentedAsModal: $isFlipped) }
          .sheet(isPresented: $isFlipped) { PortForwardingRulesView() }
            
            HStack {
                Image(systemName: "clock")
                  .modifier(ImageStyle())
                  
                Text("5 hours")
                  
            }.modifier(HeaderElement())
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
          .foregroundColor(Color.white)
          .background(Color(hex: "1C1C1E"))
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
        .background(Color(hex: "3A3A3C").opacity(0.8))
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
            .padding(.horizontal, BKDashboardCornerRadius)
          .foregroundColor(Color.white)
//            .padding(.vertical, 1)
    }
}

struct ImageStyle: ViewModifier {
    func body(content: Content) -> some View {
      content.frame(width: 34, height: 34, alignment: .center)
    }
}

//struct EffectsView: UIViewRepresentable {
//  var material: UIBlurEffect
//
//  /// https://pspdfkit.com/blog/2020/blur-effect-materials-on-ios/
//  func makeUIView(context: Context) -> some UIView {
//    let visualEffectView = UIVisualEffectView()
//
//
//    visualEffectView.effect = material
//
//    let vibrancyEffect = UIVibrancyEffect(blurEffect: material, style: .fill)
//
//    // Add a new `UIVibrancyEffectView` to the `contentView` of the earlier added `UIVisualEffectView`.
//    let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
//    vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false
//
//    visualEffectView.contentView.addSubview(vibrancyEffectView)
//
//    return visualEffectView
//  }
//
//
//  func updateUIView(_ uiView: UIViewType, context: Context) {
//    (uiView as! UIVisualEffectView).effect = material
//  }
//}

// MARK: Previews

//struct BKDashboard_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
////            CommonActions(progressValue: 0.7)
////                .previewDevice("iPhone 12 mini")
//            BKDashboard()
//                .previewDevice("iPhone 12 mini")
//                .colorScheme(.light)
//            BKDashboard()
//                .previewDevice("iPhone 12 mini")
//                .colorScheme(.dark)
//            BKDashboard()
//                .previewDevice("iPhone 12 mini")
//        }
//    }
//}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
