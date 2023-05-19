//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// numField.swift
/// Copyright 2015-2021 Robert T. Miller
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
//  numField.swift
//  rTracker
//
//  Used by voNumber through rTracker-resource to create a numeric
//   keyboard with a '-' key
//
//  Created by Rob Miller on 15/09/2015.
//  Copyright (c) 2015 Robert T. Miller. All rights reserved.
//

import UIKit

class numField: UITextField {
    @objc func minusKey() {
        text = rTracker_resource.negateNumField(text)
    }
}