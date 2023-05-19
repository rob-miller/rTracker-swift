//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// dpRslt.swift
/// Copyright 2011-2021 Robert T. Miller
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
//  dpRslt.swift
//  rTracker
//
//  Created by Rob Miller on 18/05/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

import Foundation

let DPA_CANCEL = 0
let DPA_NEW = 1
let DPA_SET = 2
let DPA_GOTO = 3
let DPA_GOTO_POST = 4


class dpRslt: NSObject {
    /*
     {
    	NSDate *date;
    	NSInteger action;
    }*/
    var date: Date?
    var action = 0

    override init() {
        super.init()
        action = DPA_CANCEL
    }
}