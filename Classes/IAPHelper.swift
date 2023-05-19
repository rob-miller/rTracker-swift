//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// IAHelper.h
/// Copyright 2015-2016 Robert T. Miller
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
/// http://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///***************

//
//  IAPHelper.swift
//  rTracker
//
//  Created by Rob Miller on 09/05/2015.
//  Copyright (c) 2015 Robert T. Miller. All rights reserved.
//

///************
/// IAHelper.m
/// Copyright 2015-2016 Robert T. Miller
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
/// http://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///***************

//
//  IAPHelper.swift
//  rTracker
//
//  Created by Rob Miller on 09/05/2015.
//  Copyright (c) 2015 Robert T. Miller. All rights reserved.
//

import StoreKit

let IAPHelperProductPurchasedNotification: String? = nil
typealias RequestProductsCompletionHandler = (Bool, [AnyHashable]?) -> Void

let IAPHelperProductPurchasedNotification = "IAPHelperProductPurchasedNotification"

class IAPHelper: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    // 3
    private var productsRequest: SKProductsRequest?
    // 4
    private var completionHandler: RequestProductsCompletionHandler?
    private var productIdentifiers: Set<AnyHashable>?
    private var purchasedProductIdentifiers: Set<AnyHashable>?

    init(productIdentifiers: Set<AnyHashable>?) {

        super.init()
        // Store product identifiers
        self.productIdentifiers = productIdentifiers

        // Check for previously purchased products
        purchasedProductIdentifiers = []
        for productIdentifier in self.productIdentifiers ?? [] {
            guard let productIdentifier = productIdentifier as? String else {
                continue
            }
            let productPurchased = UserDefaults.standard.bool(forKey: productIdentifier)
            if productPurchased {
                purchasedProductIdentifiers?.insert(productIdentifier)
                DBGLog("Previously purchased: %@", productIdentifier)
                //[rTracker_resource alert:@"Previously Purchased" msg:@"Previous rTracker purchase found." vc:nil];
            } else {
                DBGLog("Not purchased: %@", productIdentifier)
                //[rTracker_resource alert:@"Not Previously Purchased" msg:@"No previous rTracker purchase found." vc:nil];
            }
        }
        SKPaymentQueue.default().addTransactionObserver(self)
    }

    func requestProducts(with completionHandler: RequestProductsCompletionHandler) {
        DBGLog("rpwch")
        // 1
        self.completionHandler = completionHandler.copy()

        // 2
        if let productIdentifiers = productIdentifiers as? Set<String> {
            productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        }
        productsRequest?.delegate = self
        productsRequest?.start()

    }

    // MARK: - SKProductsRequestDelegate

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {

        DBGLog("Loaded list of products...")
        productsRequest = nil

        let skProducts = response.products

        #if DEBUGLOG
        for skProduct in skProducts {
            DBGLog(
                "Found product: %@ %@ %0.2f",
                skProduct.productIdentifier,
                skProduct.localizedTitle,
                skProduct.price.floatValue)
        }
        #endif

        completionHandler?(true, skProducts)
        completionHandler = nil

    }

    func request(_ request: SKRequest, didFailWithError error: Error) {

        DBGLog("Failed to load list of products.")
        //[rTracker_resource alert:@"Connection failure" msg:@"Failed to load list of available products." vc:nil];

        productsRequest = nil

        if completionHandler != nil {
            // can be nil already if user repeatedly presses button on timeout
            completionHandler?(false, nil)
        }
        completionHandler = nil

    }

    @objc func productPurchased(_ productIdentifier: String?) -> Bool {
        return purchasedProductIdentifiers?.contains(productIdentifier ?? "") ?? false
    }

    func buy(_ product: SKProduct?) {

        DBGLog("Buying %@...", product?.productIdentifier)

        var payment: SKPayment? = nil
        if let product {
            payment = SKPayment(product: product)
        }
        SKPaymentQueue.default().add(payment)

    }

    func provideContent(forProductIdentifier productIdentifier: String?) {

        purchasedProductIdentifiers?.insert(productIdentifier)
        UserDefaults.standard.set(true, forKey: productIdentifier ?? "")
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name(IAPHelperProductPurchasedNotification), object: productIdentifier, userInfo: nil)

    }

    func complete(_ transaction: SKPaymentTransaction?) {
        DBGLog("completeTransaction...")

        provideContent(forProductIdentifier: transaction?.payment.productIdentifier)
        SKPaymentQueue.default().finish(transaction)
    }

    func restore(_ transaction: SKPaymentTransaction?) {
        DBGLog("restoreTransaction...")

        provideContent(forProductIdentifier: transaction?.original?.payment.productIdentifier)
        SKPaymentQueue.default().finish(transaction)
    }

    func restoreCompletedTransactions() {
        DBGLog("restore completed Transactions...")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    func failedTransaction(_ transaction: SKPaymentTransaction?) {

        DBGLog("failedTransaction...")
        if (transaction?.error as NSError?)?.code != SKError.Code.paymentCancelled.rawValue {
            DBGLog("Transaction error: %@", transaction?.error?.localizedDescription)
            //[rTracker_resource alert:@"In-App Purchase Transaction Failed" msg:[@"Transaction error: " stringByAppendingString:transaction.error.localizedDescription] vc:nil];
        }

        SKPaymentQueue.default().finish(transaction)
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                complete(transaction)
            case .failed:
                failedTransaction(transaction)
            case .restored:
                restore(transaction)
            default:
                break
            }
        }
    }
}

//#import "rTracker-resource.h"