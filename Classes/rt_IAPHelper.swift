//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// rt_IAHelper.h
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
//  rt_IAPHelper.swift
//  rTracker
//
//  Created by Rob Miller on 09/05/2015.
//  Copyright (c) 2015 Robert T. Miller. All rights reserved.
//
// original source: http://www.raywenderlich.com/21081/introduction-to-in-app-purchases-in-ios-6-tutorial
//

///************
/// rt_IAHelper.m
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
//  rt_IAPHelper.swift
//  rTracker
//
//  Created by Rob Miller on 09/05/2015.
//  Copyright (c) 2015 Robert T. Miller. All rights reserved.
//

let IAPHelperProductPurchasedNotification: String? = nil

class rt_IAPHelper: IAPHelper {
    @objc class func productPurchased(_ notification: Notification?) {

        let productIdentifier = notification?.object as? String
        if RTA_prodid == productIdentifier {
            rTracker_resource.setPurchased(true)
            DBGLog("purchased!")
        }
    }


    static let sharedInstanceVar: rt_IAPHelper? = {
        var sharedInstance = self.init(productIdentifiers: productIdentifiers)
        NotificationCenter.default.addObserver(self, selector: #selector(IAPHelper.productPurchased(_:)), name: NSNotification.Name(IAPHelperProductPurchasedNotification), object: nil)
        return sharedInstance
    }()

    class func sharedInstance() -> rt_IAPHelper? {
        // `dispatch_once()` call was converted to a static variable initializer


        return sharedInstanceVar
    }

    @objc override func productPurchased(_ productIdentifier: String?) -> Bool {
        return super.productPurchased(productIdentifier)
    }

    override func buy(_ product: SKProduct?) {
        super.buy(product)
    }
}