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
import SwiftUI

// TODO: Integrate with SSH Wrapper

@objc class PortForwardHostingController: NSObject {
  
  @objc static func createWith(nav: UINavigationController?) -> UIViewController {
    let rootView = PortForwardingRulesView()
    
    guard let nav = nav else {
      return UIHostingController(rootView: rootView)
    }
    return UIHostingController(rootView: NavView(navController: nav)  { rootView } )
  }
}

struct PortForwardingRulesView: View {
  
  @State var allRules = BKPortForwardRule.all()
  @State var activeRules: [BKPortForwardRule] = []
  
  var body: some View {
    
      VStack {
        List {
          Section(header: Text("\(allRules.count) saved rules found")) {
            if allRules.count == 0 {
              Text("No port forwarding rules found.")
            } else {
              ForEach(allRules, id:\.id) { rule in
                
                NavigationLink(destination: NewPortForwardRuleView(rule: rule), label: {
                  HStack {
                    if rule.tunnelType == "Local" {
                      Image(systemName: "l.circle.fill")
                    } else if rule.tunnelType == "Remote" {
                      Image(systemName: "r.circle.fill")
                    }
                    
                    VStack(alignment: .leading) {
                      Text("\(rule.label == nil ? rule.destination: rule.label!)")
                        .bold()
                      
                      Text("\(rule.portFrom):\(rule.destination):\(rule.portTo)")
                        .font(.system(.body, design: .monospaced))
                    }
                  }
                })
                
              }.onDelete(perform: delete)
            }
          }
          
          Section(header: Text("\(activeRules.count) active rules")) {
            if allRules.count == 0 {
              Text("No active port forward rules.")
            } else {
              ForEach(activeRules, id:\.id) { rule in
                
                NavigationLink(destination: NewPortForwardRuleView(), label: {
                  HStack {
                    if rule.tunnelType == "Local" {
                      Image(systemName: "l.circle.fill")
                    } else if rule.tunnelType == "Remote" {
                      Image(systemName: "r.circle.fill")
                    }
                    
                    VStack {
                      Text("\(rule.tunnelType) \(rule.portFrom):\(rule.destination):\(rule.portTo)")
                    }
                  }
                })
                
              }.onDelete(perform: stopRule)
            }
          }
        }.listStyle(InsetGroupedListStyle())
      }
      .navigationTitle(Text("Port forwarding"))
      .navigationBarItems(trailing:
                            
        NavigationLink(destination: NewPortForwardRuleView(), label: {
          Text("New Rule")
        })
      )

  }
  
  func delete(at offsets: IndexSet) {
    BKPortForwardRule.deleteAtIndex(offset: offsets)
    allRules.remove(atOffsets: offsets)
  }
  
  func stopRule(at offsets: IndexSet) {
    // TODO: do this when the wrapper is connected
  }
}


/**
 Aid view to help users realise what port forwarding operation they're creating
 */
struct PortForwardAidView: View {
  
  @Binding var allHosts: [BKHosts]
  @Binding var selectedHost: Int
  @Binding var destination: String
  @Binding var portFrom: String
  @Binding var bindAddress: String
  @Binding var portTo: String
  @Binding var type: SSHPortForwardType
  
  var body: some View {
    
    if allHosts.isEmpty {
    
      Text("Please, create a host before creating Port Forwarding rules.").bold()
      
    } else {
      VStack(alignment: .leading) {
        
        if !allHosts[selectedHost].host.isEmpty && !portFrom.isEmpty && !portTo.isEmpty && !bindAddress.isEmpty {
          Text("Equivalent to ") +
            Text("ssh -\(String(type.rawValue.prefix(1))) \(portFrom):\(destination):\(portTo) \(bindAddress).\n")
            .font(.system(.caption, design: .monospaced))
          
          if type == SSHPortForwardType.local {
            Text("In ") + Text("local port forwarding").bold() + Text(" the SSH client listens for communication from the application client and therefore usually resides on the same box as the application client.\n")
            
            Text("All traffic sent to port \(portFrom) on your localhost is being forwarded to port \(portTo) on the remote server located at \(destination).\n")
          } else if type == .remote {
            Text("In ") + Text("remote port forwarding").bold() + Text(" the SSH server listens for communication from the application client, the SSH server and application client reside on the same host.\n")
            
            Text("SSH server binds to the \(portFrom) on \(bindAddress). Any traffic received received on this port is sent to the SSH client on Blink  which in turn is forwarded to port \(portTo) on \(destination). You can open \(bindAddress):\(portFrom).")
          }
        }
        
        Text("Due to system limitations Port Forwarding is active whenever Blink is open in the foreground or split view.").bold()
      }
    }
  }
}

class PortForwardRuleViewModel: ObservableObject {
  
  @Published var allHosts: [BKHosts] = ((BKHosts.all() as? [BKHosts]) != nil) ? BKHosts.all() as! [BKHosts] : []
  @Published var destination: String = ""
  @Published var label: String = ""
  @Published var portFrom: String = ""
  @Published var bindAddress: String = ""
  @Published var portTo: String = ""
  @Published var enabled: Bool = false
  /// Types of tunnels offered by the app
  var tunnelType: [SSHPortForwardType] = [.local, .remote, .dynamic]
  @Published var selectedTunnelType: Int = 0
  @Published var selectedHost: Int = 0
}

struct NewPortForwardRuleView: View {
  
  var rule: BKPortForwardRule?
  
  @ObservedObject var viewModel = PortForwardRuleViewModel()
  
  @State var hasChanged: Bool = false
  
  init(rule: BKPortForwardRule? = nil) {
    self.rule = rule
    
    if let rule = rule {
      viewModel.destination = rule.destination
      viewModel.portTo = rule.portTo
      viewModel.portFrom = rule.portFrom
      viewModel.selectedTunnelType = SSHPortForwardType.allCases.firstIndex(of: SSHPortForwardType(rawValue: rule.tunnelType)!)!
    }
  }
  
  var body: some View {
    
    VStack {
      
      Form {
        
        Picker("Port Forwarding", selection: $viewModel.selectedTunnelType, content: {
          ForEach(0..<viewModel.tunnelType.count) { i in
            Text(viewModel.tunnelType[i].rawValue)
          }
        }).pickerStyle(SegmentedPickerStyle())
        
        Section(footer: PortForwardAidView(allHosts: $viewModel.allHosts,
                                           selectedHost: $viewModel.selectedHost,
                                           destination: $viewModel.destination,
                                           portFrom: $viewModel.portFrom,
                                           bindAddress: $viewModel.bindAddress, portTo: $viewModel.portTo, type: $viewModel.tunnelType[viewModel.selectedTunnelType])) {
          
          TextField("Label", text: $viewModel.label)
        
        if viewModel.allHosts.isEmpty {
          
          HStack {
            Text("Host")
            
            Spacer()
            
            Text("Create host").redacted(reason: .placeholder)
          }
        } else {
          Picker("Host", selection: $viewModel.allHosts[viewModel.selectedHost], content: {
            ForEach(viewModel.allHosts, id: \.self) { host in
              Text(host.host)
            }
          })
        }
          
          TextField("Port from", text: $viewModel.portFrom).keyboardType(.decimalPad)
          
          TextField("Destination", text: $viewModel.destination)
          
          TextField("Port To", text: $viewModel.portTo).keyboardType(.decimalPad)
          
          Toggle("Enabled", isOn: $viewModel.enabled)
        }
        
        Section {
          TextField("Bind Address", text: $viewModel.bindAddress)
        }
      }
      .disabled( viewModel.allHosts.isEmpty )
    }
    .navigationTitle(rule == nil ? Text("New Rule") : Text("\(rule!.portFrom):\(rule!.destination):\(rule!.portTo)"))
    .navigationBarItems(trailing:
                          Button(action: {
                            
                            if rule == nil {
                              BKPortForwardRule.save(label: viewModel.label.isEmpty ? nil : viewModel.label, type: viewModel.tunnelType[viewModel.selectedTunnelType], portFrom: viewModel.portFrom, portTo: viewModel.portTo, destination: viewModel.destination)
                            } else {
                              // TODO: Update already existing rule
                            }
                          }, label: {
                            Text("Save")
                          })
                          .disabled(viewModel.portFrom.isEmpty && viewModel.destination.isEmpty && viewModel.portTo.isEmpty && viewModel.allHosts.isEmpty)
    )
  }
}


