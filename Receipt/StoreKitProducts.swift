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

// TODO: - Add the available products from App Store Connect
public struct StoreKitProducts {
    
    public static let FirstProduct = "Com.CarlosCabanero.BlinkShell.suscription_level_1"
    public static let SecondProduct = "Com.CarlosCabanero.BlinkShellNew.MonthlyTier"
    public static let ThirdProduct = "Com.CarlosCabanero.BlinkShell.suscription_level_2"
    public static let FourthProduct = "Com.CarlosCabanero.BlinkShell.unlock_all"
    
    private static let productIdentifiers: Set<ProductIdentifier> = [StoreKitProducts.SecondProduct, StoreKitProducts.ThirdProduct, StoreKitProducts.FourthProduct]
    
    public static let store = IAPHelper(productIds: StoreKitProducts.productIdentifiers)
}

struct BKPurchase: Identifiable {
    var id = UUID()
    var localizedTitle: String
    var identifier: String
    var skProd: SKProduct
}

