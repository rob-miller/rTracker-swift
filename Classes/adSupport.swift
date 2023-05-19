//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// adSupport.swift
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
//  adSupport.swift
//  rTracker
//
//  Created by Rob Miller on 02/04/2015.
//  Copyright (c) 2015 Robert T. Miller. All rights reserved.
//

///************
/// adsupport.m
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
//  adSupport.swift
//  rTracker
//
//  Created by Rob Miller on 02/04/2015.
//  Copyright (c) 2015 Robert T. Miller. All rights reserved.
//

import Foundation
import iAd

class adSupport: NSObject {
    private var _bannerView: ADBannerView?
    var bannerView: ADBannerView? {
        if _bannerView == nil {
            // On iOS 6 ADBannerView introduces a new initializer, use it when available.
            if ADBannerView.instancesRespond(to: Selector("initWithAdType:")) {
                _bannerView = ADBannerView(adType: ADAdTypeBanner)
            } else {
                _bannerView = ADBannerView()
            }
        }
        return _bannerView
    }

    func initBannerView(_ delegate: ADBannerViewDelegate?) {
        bannerView?.delegate = delegate
    }

    func layoutAnimated(_ vc: UIViewController?, tableview: UITableView?, animated: Bool) {
        // As of iOS 6.0, the banner will automatically resize itself based on its width.

        //CGRect contentFrame = view.bounds;
        var contentFrame = vc?.view.bounds
        contentFrame?.size = rTracker_resource.get_visible_size(vc)
        let bannerFrame = bannerView?.frame

        DBGLog("in: cf x %f y %f  w %f h %f", contentFrame?.origin.x, contentFrame?.origin.y, contentFrame?.size.width, contentFrame?.size.height)
        DBGLog("in: bf x %f y %f  w %f h %f", bannerFrame?.origin.x, bannerFrame?.origin.y, bannerFrame?.size.width, bannerFrame?.size.height)

        if bannerView?.bannerLoaded {
            contentFrame?.size.height -= bannerView?.frame.size.height ?? 0.0
            bannerFrame?.origin.y = contentFrame?.size.height ?? 0.0
            DBGLog("banner is loaded")
        } else {
            DBGLog("banner not loaded")
            bannerFrame?.origin.y = contentFrame?.size.height ?? 0.0
        }
        DBGLog("out: cf x %f y %f  w %f h %f", contentFrame?.origin.x, contentFrame?.origin.y, contentFrame?.size.width, contentFrame?.size.height)
        DBGLog("out: bf x %f y %f  w %f h %f", bannerFrame?.origin.x, bannerFrame?.origin.y, bannerFrame?.size.width, bannerFrame?.size.height)
        //DBGLog(@"foo");
        UIView.animate(withDuration: animated ? 0.25 : 0.0, animations: { [self] in
            //_contentView.frame = contentFrame;
            //[_contentView layoutIfNeeded];
            tableview?.frame = contentFrame ?? CGRect.zero
            tableview?.layoutIfNeeded()
            bannerView?.frame = bannerFrame
        })
    }
}