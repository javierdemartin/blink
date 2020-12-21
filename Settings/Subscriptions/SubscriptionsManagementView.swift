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
import StoreKit

enum ActivePurchase {
  case none
  case purchase(name: BKPurchase)
  
  var description: String {
    switch self {
    case .none:
      return "None"
    case .purchase(name: let purchase):
      return purchase.localizedTitle
    }
  }
}


struct SubscriptionsManagementView: View {
  
  @State var pub = NotificationCenter.default
    .publisher(for: NSNotification.Name(Notification.Name.IAPHelperPurchaseNotification.rawValue))
  
  
  @State var products: [BKPurchase] = []
  @State var activePurchase: ActivePurchase = .none
  
  var body: some View {
    List {
      
      Section(header: Text("Available tiers")) {
        ForEach(products) { p in
          
          Button(action: {
            StoreKitProducts.store.buyProduct(p.skProd)
            
          }) {
            HStack {
              Text(p.localizedTitle)
              Spacer()
              Text(p.skProd.localizedPrice)
            }
          }
        }
      }
      
      Section(header: Text("Subscription status")) {
        Text(activePurchase.description)
      }
    }
    .listStyle(GroupedListStyle())
    .navigationBarTitle(Text("Subscription status"))
    .onAppear(perform: {
      
      StoreKitProducts.store.requestProducts({ success, products in
        
        if success {
          
          guard let productos = products else { return }
          
          DispatchQueue.main.async {
            productos.forEach({ prod in  self.products.append(BKPurchase(localizedTitle: prod.localizedTitle, identifier: prod.productIdentifier, skProd: prod))
            })
          }
        }
      })
    })
    .navigationBarItems(trailing:
                          Button(
                            action: {
                              blink_openurl(URL(string: "https://apps.apple.com/account/subscriptions")!)
                            },
                            label: { Text("Manage") }
                          )
    )
    .onReceive(pub) { identifier in
      
      guard let pId = identifier.object as? String else {
        return
      }
      
      self.updateCurrentSubscriptionStatus(identifier: pId)
    }
  }
  
  
  func updateCurrentSubscriptionStatus(identifier: String) {
    // do stuff
    
    guard let boughtProduct = products.filter({ $0.identifier == identifier}).first else {
      return
    }
    
    activePurchase = .purchase(name: boughtProduct)
  }
}

struct SubscriptionsManagementView_Previews: PreviewProvider {
  static var previews: some View {
    SubscriptionsManagementView()
  }
}
