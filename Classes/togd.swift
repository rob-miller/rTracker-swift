//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// togd.swift
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
//  togd.swift
//
//  Tracker Object Graph Data
//
//  rTracker
//
//  Created by Rob Miller on 10/05/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

import Foundation

class Togd: NSObject {
    /*{
        trackerObj *pto;
        CGRect rect;
        CGRect bbox;
    	int firstDate;
    	int lastDate;
        double dateScale;
        double dateScaleInv;
    }*/
    var pto: trackerObj?
    var rect = CGRect.zero
    var bbox = CGRect.zero
    var firstDate = 0
    var lastDate = 0
    var dateScale = 0.0
    var dateScaleInv = 0.0

    override convenience init() {
        self.init(data: nil, rect: .zero)
    }

    init(data pTracker: trackerObj?, rect inRect: CGRect) {

        super.init()
        pto = pTracker
        rect = inRect
        bbox = inRect

        var sql = "select max(date) from voData;"
        lastDate = pto?.toQry2Int(sql:sql) ?? 0

        var gmd = (pto?.optDict["graphMaxDays"] as? NSNumber)?.intValue ?? 0
        if 0 != gmd {
            var tFirstDate: Int
            gmd *= 60 * 60 * 24 // secs per day
            tFirstDate = lastDate - gmd
            sql = "select min(date) from voData where date >= \(tFirstDate);"
        } else {
            sql = "select min(date) from voData;"
        }
        firstDate = pto?.toQry2Int(sql:sql) ?? 0
        //sql = nil

        if firstDate == lastDate {
            firstDate -= 60 * 60 * 24 // secs per day -- single data point so arbitrarily set scale to 1 day
        }

        let dateScaleExpand = Int(((Double(lastDate) - Double(firstDate)) * GRAPHSCALE) + d(0.5))
        lastDate += dateScaleExpand
        firstDate -= dateScaleExpand

        dateScale = d(rect.size.width) / (d(lastDate) - d(firstDate))
        dateScaleInv = d(lastDate - firstDate) / d(rect.size.width)
    }

    func fillVOGDs() {
        for vo in pto?.valObjTable ?? [] {
            let tvogd = vo.vos?.newVOGD()
            vo.vogd = tvogd as? (vogd & voProtocol)
            //[vo.vogd release]; // rtm 05 feb 2012  +1 for new (alloc), +1 for vo retain
        }
    }
}
