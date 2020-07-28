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
import StoreKit

protocol SuscriptionSettingsViewModelDelegate: class {
  
  func didFinishStoreKitUpdateOperation()
}

extension SKProduct {
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)!
    }
}

extension SKProduct.PeriodUnit {
    func description(capitalizeFirstLetter: Bool = false, numberOfUnits: Int? = nil) -> String {
        let period:String = {
            switch self {
            case .day: return "day"
            case .week: return "week"
            case .month: return "month"
            case .year: return "year"
            }
        }()

        var numUnits = ""
        var plural = ""
        if let numberOfUnits = numberOfUnits {
            numUnits = "\(numberOfUnits) " // Add space for formatting
            plural = numberOfUnits > 1 ? "s" : ""
        }
        return "\(numUnits)\(capitalizeFirstLetter ? period.capitalized : period)\(plural)"
    }
}

class SuscriptionSettingsViewModel {
  
  var appStoreAvailableProducts: [SKProduct] = []
  weak var delegate: SuscriptionSettingsViewModelDelegate?
  
  init() {
    StoreKitProducts.store.delegate = self
    
    StoreKitProducts.store.requestProducts({ [weak self] success, products in

        guard let self = self else { return }

        if success {
            dump(products)

            guard let products = products else { return }

            NotificationCenter.default.addObserver(self, selector: #selector(self.didSuccessfullyFinishStoreKitOperation), name: .IAPHelperPurchaseNotification, object: nil)

//            StoreKitProducts.store.buyProduct(foundProduct!)
        }
    })
  }
  
  func buy(product: SKProduct) {
    StoreKitProducts.store.buyProduct(product)
  }
  
  @objc func didSuccessfullyFinishStoreKitOperation() {

      print("FINISH")
  }
}

extension SuscriptionSettingsViewModel: IAPHelperDelegate {
  func finishedRestoringPurchases() {
    
  }
  
  func gotProductIdentifiersAndPricing(products: [SKProduct]) {
    dump(products)
    appStoreAvailableProducts = products
    delegate?.didFinishStoreKitUpdateOperation()
  }
  
  func didFail(with error: String) {
    print(error)
  }
//
//  func previouslyPurchased(status: Bool) {
//    print(status)
//  }
//
  
}
