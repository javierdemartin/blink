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
import UIKit

extension SuscriptionSettingsViewController: SuscriptionSettingsViewModelDelegate {
  func didFinishStoreKitUpdateOperation() {
    DispatchQueue.main.async {
      self.tableView.reloadData()
    }
  }
}

class SuscriptionSettingsViewController: UITableViewController {
  
  let suscriptionViewModel: SuscriptionSettingsViewModel
  
  let cellReuseIdentifier = "Cell"
  
  let cellReuseIdentifiers = ["0": "options", "1": "status", "2": "current-suscription"]
  let cellsDescriptors = ["1": ["Restore purchases", "Read more"], "2": ["Not currently suscribed"]]
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    suscriptionViewModel = SuscriptionSettingsViewModel()
    
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    
    suscriptionViewModel.delegate = self
  }
  
  required init?(coder: NSCoder) {
    
    suscriptionViewModel = SuscriptionSettingsViewModel()
    
    super.init(coder: coder)
    
    suscriptionViewModel.delegate = self

  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    switch section {
    case 0:
      // If no products have already been retrieved from the App Store show a single cell
      // acting as a loading state
      if suscriptionViewModel.appStoreAvailableProducts.count == 0 {
        return 1
      }
      
      return suscriptionViewModel.appStoreAvailableProducts.count
    case 1:
      return cellsDescriptors["1"]!.count
    case 2:
      return cellsDescriptors["2"]!.count
    default:
      return 0
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
    
    switch indexPath.section {
    case 0:
      
      guard let caseIdentifier = cellReuseIdentifiers["\(indexPath.section)"] else {
        return cell
      }
      
      if suscriptionViewModel.appStoreAvailableProducts.count == 0 {
        
        cell = UITableViewCell(style: .default, reuseIdentifier: caseIdentifier)
        cell.textLabel?.text = "Loading..."
        cell.selectionStyle = .none
        
        return cell
      }
      
      cell = UITableViewCell(style: .value1, reuseIdentifier: caseIdentifier)
      
      guard let suscriptionPeriod = suscriptionViewModel.appStoreAvailableProducts[indexPath.row].subscriptionPeriod else {
        return cell
      }
      
      cell.textLabel?.text = suscriptionViewModel.appStoreAvailableProducts[indexPath.row].localizedTitle
      
      cell.detailTextLabel?.text = "\(suscriptionViewModel.appStoreAvailableProducts[indexPath.row].localizedPrice) / \(suscriptionPeriod.unit.description(capitalizeFirstLetter: false, numberOfUnits: suscriptionPeriod.numberOfUnits))"

    case 1:
      
      guard let cellsContents = cellsDescriptors["1"] else {
        return cell
      }
      
      guard let caseIdentifier = cellReuseIdentifiers["\(indexPath.section)"] else {
        return cell
      }
      
      cell = UITableViewCell(style: .default, reuseIdentifier: caseIdentifier)
            
      cell.textLabel?.text = cellsContents[indexPath.row]
    case 2:
      
      guard let caseIdentifier = cellReuseIdentifiers["\(indexPath.section)"] else {
        return cell
      }
      
      // Disable cell selection as it doesn't need to do any action
      cell.selectionStyle = .none
      cell = UITableViewCell(style: .default, reuseIdentifier: caseIdentifier)
      cell.textLabel?.text = ReceiptFetcher.sharedInstance().currentSuscription
    default:
      return cell
    }
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
 
    switch section {
    case 0:
      return "Options"
    case 1:
      return "Status"
    case 2:
      return "Current Suscription"
    default:
      return nil
    }
  }
  
  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    switch section {
    case 0:
      return "Blink shell suscriptions let you unlock the full potential of the app."
    case 1:
      return "To manage your suscriptions go to your account in the App Store and then tap on Suscriptions."
    case 2:
      if ReceiptFetcher.sharedInstance().hasBoughtOgBlink {
        return "You already have Blink 13, thank you for your support."
      } else if ReceiptFetcher.sharedInstance().currentSuscriptionExpirationDateString.count > 0 {
        let footerString = "Current suscription expires on \(ReceiptFetcher.sharedInstance().currentSuscriptionExpirationDateString), in \(ReceiptFetcher.sharedInstance().currentSuscriptionExpirationDate)."
        
        return footerString
      }
      
      return nil
      
    default:
      return nil
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      
    switch indexPath.section {
    // Purchase section
    case 0:
      if suscriptionViewModel.appStoreAvailableProducts.count > 0 {
        suscriptionViewModel.buy(product: suscriptionViewModel.appStoreAvailableProducts[indexPath.row])
      }
    case 1:
      if indexPath.row == 0 {
        StoreKitProducts.store.restorePurchases()
      }
      else if indexPath.row == 1 {
        blink_openurl(URL(string: "https://blink.sh/suscriptions"))
      }
    default:
      break
    }
  }
  
  @objc func didSuccessfullyFinishStoreKitOperation() {

      print("FINISHED RESTORING")
  }
}
