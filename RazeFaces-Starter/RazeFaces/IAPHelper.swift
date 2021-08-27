/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import StoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

extension Notification.Name {
  static let IAPHelperPurchaseNotification = Notification.Name("IAPHelperPurchaseNotification")
}

open class IAPHelper: NSObject  {
    private let productIdentifiers: Set<ProductIdentifier> // Set of Purchasable product ID's
    private var purchasedProductIdentifiers: Set<ProductIdentifier> = [] // Set of purchased product ID's
    private var productsRequest: SKProductsRequest? // SKProduct payment request object
    private var productsRequestCompletionHandler: ProductsRequestCompletionHandler? // SKProduct request handler
  
    public init(productIds: Set<ProductIdentifier>) {
      productIdentifiers = productIds // Taking product ID's from RazeFaceProducts class
      for productIdentifier in productIds {
        let purchased = UserDefaults.standard.bool(forKey: productIdentifier) // Checking if product ID's have already been purchased
        if purchased {
          purchasedProductIdentifiers.insert(productIdentifier) // Adding ID's to purchased ID set
          print("Previously purchased: \(productIdentifier)")
        } else {
          print("Not purchased: \(productIdentifier)")
        }
      }
      super.init()
      SKPaymentQueue.default().add(self)
      
    }
  
}

// MARK: - StoreKit API

extension IAPHelper {
  
  public func requestProducts(completionHandler: @escaping ProductsRequestCompletionHandler) { // Requesting products from app store
    productsRequest?.cancel()
    productsRequestCompletionHandler = completionHandler

    productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
    productsRequest!.delegate = self
    productsRequest!.start()
  }

  public func buyProduct(_ product: SKProduct) {
    print("Buying \(product.productIdentifier)...")
    let payment = SKPayment(product: product) // Creating SKPayment for transaction
    SKPaymentQueue.default().add(payment) // Adding transaction to SKPayment queue
  }

  public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
    return purchasedProductIdentifiers.contains(productIdentifier) // Returns whether product has previously been purchased
  }
  
  public class func canMakePayments() -> Bool {
    return SKPaymentQueue.canMakePayments() // Returns whether user is eligable to make purchases
  }
  
  public func restorePurchases() {
    SKPaymentQueue.default().restoreCompletedTransactions() // Restores previous transactions
  }
  
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate { // Extension for product request function called earlier

  public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) { // Successfully requested and recieved products from app store
    print("Loaded list of products...")
    let products = response.products
    productsRequestCompletionHandler?(true, products)
    clearRequestAndHandler()

    for p in products {
      print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
    }
  }
  
  public func request(_ request: SKRequest, didFailWithError error: Error) { // Failed to request or recieve products from app store
    print("Failed to load list of products.")
    print("Error: \(error.localizedDescription)")
    productsRequestCompletionHandler?(false, nil)
    clearRequestAndHandler()
  }

  private func clearRequestAndHandler() { // Ending requests to apple servers
    productsRequest = nil
    productsRequestCompletionHandler = nil
  }
}

// MARK: - SKPaymentTransactionObserver
 
extension IAPHelper: SKPaymentTransactionObserver { // Extension for SKPayment and SKProduct functions called earlier
 
  public func paymentQueue(_ queue: SKPaymentQueue,
                           updatedTransactions transactions: [SKPaymentTransaction]) { // Queue of SKPayment transaction requests
    for transaction in transactions {
      switch transaction.transactionState { // Handles transaction states, self explanitory
      case .purchased:
        complete(transaction: transaction)
        break
      case .failed:
        fail(transaction: transaction)
        break
      case .restored:
        restore(transaction: transaction)
        break
      case .deferred:
        break
      case .purchasing:
        break
      }
    }
  }
 
  private func complete(transaction: SKPaymentTransaction) { // Transaction successful
    print("complete...")
    deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier) // Calling function for successful transaction
    SKPaymentQueue.default().finishTransaction(transaction) // Finalizing transaction
  }
 
  private func restore(transaction: SKPaymentTransaction) { // Restore successful
    guard let productIdentifier = transaction.original?.payment.productIdentifier else { return } // Grabbing previous transaction to be restored, do nothing if product doesn't exist
 
    print("restore... \(productIdentifier)")
    deliverPurchaseNotificationFor(identifier: productIdentifier)
    SKPaymentQueue.default().finishTransaction(transaction)
  }
 
  private func fail(transaction: SKPaymentTransaction) { // Transaction Fail
    print("fail...")
    if let transactionError = transaction.error as NSError?, // Printing localized description of transaction error
      let localizedDescription = transaction.error?.localizedDescription,
        transactionError.code != SKError.paymentCancelled.rawValue {
        print("Transaction Error: \(localizedDescription)")
      }

    SKPaymentQueue.default().finishTransaction(transaction)
  }
 
  private func deliverPurchaseNotificationFor(identifier: String?) {
    guard let identifier = identifier else { return } // Grabbing product identifier, do nothing if product doesn't exist
 
    purchasedProductIdentifiers.insert(identifier) // Add product to purchased products set
    UserDefaults.standard.set(true, forKey: identifier)
    NotificationCenter.default.post(name: .IAPHelperPurchaseNotification, object: identifier)
  }

  
}
