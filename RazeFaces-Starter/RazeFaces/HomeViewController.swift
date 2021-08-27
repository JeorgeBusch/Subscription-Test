//
//  HomeViewController.swift
//  RazeFaces
//
//  Created by Avery on 8/26/21.
//  Copyright © 2021 Razeware LLC. All rights reserved.
//

import UIKit
import StoreKit

class HomeViewController: UIViewController {
  
    let showContentSegueIdentifier = "showContent" // Segue identifier for content page
  
    let notSubscribedSegueIdentifier = "notSubscribed" // Segue identifier for non-subscribers
  
    let isSubscribed = RazeFaceProducts.store.isProductPurchased("com.rapidrosters.iaptest.subscribe") || RazeFaceProducts.store.isProductPurchased("com.rapidrosters.iaptest.autosubscription") // Boolean for if user is subscribed
  
    override func viewDidLoad() {
        super.viewDidLoad() // Called for no particular reason, might be useful later
    }
    
    @IBAction func contentButton(_ sender: Any) { // Called when "View" button is pressed
        if isSubscribed {
            self.performSegue(withIdentifier: showContentSegueIdentifier, sender: nil) // If subscribed segue to content page
        }
        else {
            self.performSegue(withIdentifier: notSubscribedSegueIdentifier, sender: nil) // Else segue to paywall
        }
    }
    
}
