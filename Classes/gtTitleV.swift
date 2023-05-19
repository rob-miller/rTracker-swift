//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// gtTitleV.swift
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
//  gtTitleV.swift
//  rTracker
//
//  Created by Rob Miller on 12/05/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

import UIKit

class gtTitleV: UIView {
    /*{
        trackerObj *tracker;
        UIFont *myFont;    
    }*/
    var tracker: trackerObj?
    // UI element properties 
    var myFont: UIFont?

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Initialization code
        // rtm debug
        //[self setBackgroundColor:[UIColor redColor]];
    }

    override func draw(_ rect: CGRect) {
        //CGContextRef context = UIGraphicsGetCurrentContext();
        //[[UIColor whiteColor] set];

        var tsize: CGSize? = nil
        if let myFont {
            tsize = tracker?.trackerName?.size(withAttributes: [
                NSAttributedString.Key.font: myFont
            ])
        }
        var tpos = CGPoint(x: (bounds.size.width - (tsize?.width ?? 0.0)) / 2.0, y: (bounds.size.height - (tsize?.height ?? 0.0)) / 2.0)
        if tpos.x < 0 {
            tpos.x = 0
        }
        if tpos.y > bounds.size.height {
            tpos.y = bounds.size.height
        }

        //[self flipCTM];
        //CGAffineTransform tm = { 1.0f , 0.0f, 0.0f, -1.0f, 0.0f, self.bounds.size.height };
        //CGContextConcatCTM(context,tm);

        //[self.tracker.trackerName NSFontAttributeName:self.myFont];
        if let myFont {
            tracker?.trackerName?.draw(at: tpos, withAttributes: [
                NSAttributedString.Key.font: myFont,
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.backgroundColor: UIColor.black
            ])
        }
        //[self flipCTM];
        //tm = { 1.0f , 0.0f, 0.0f, -1.0f, 0.0f, self.bounds.size.height };
        ////CGContextConcatCTM(context,tm);


    }

    // MARK: -
    // MARK: private methods

    func flipCTM() {
    }

    func drawTitle() {

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}