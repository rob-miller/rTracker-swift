//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// gtXAxV.swift
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
//  gtXAxV.swift
//  rTracker
//
//  Created by Rob Miller on 12/05/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

import UIKit

class gtXAxV: UIView {
    /*{
        togd *mytogd;
        UIFont *myFont;
        CGFloat scaleOriginX;
        CGFloat scaleWidthX;
        UIScrollView *graphSV;
    }*/
    var mytogd: Togd?
    var myFont: UIFont?
    var scaleOriginX: CGFloat = 0.0
    var scaleWidthX: CGFloat = 0.0
    var graphSV: UIScrollView?
    var markDate: Date? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Initialization code
        // rtm debug
        //[self setBackgroundColor:[UIColor cyanColor]];
        //self.opaque = YES;
        //self.alpha = 1.0f;
    }

    override func draw(_ rect: CGRect) {

        // Drawing code
        let context = UIGraphicsGetCurrentContext()

        context?.clear(bounds)

        UIColor.white.set()

        MoveTo(context!, scaleOriginX, 0.0)
        AddLineTo(context!, scaleWidthX, 0.0)
        //Stroke
        context!.strokePath()
        drawXAxis(context)
        
        // Draw markDate in lower right corner if available
        if let markDate = markDate {
            drawMarkDate(context, date: markDate)
        }
    }

    func drawMarkDate(_ context: CGContext?, date: Date) {
        // Format the date (date only, no time)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let dateString = dateFormatter.string(from: date)
        
        // Calculate position for lower right corner
        guard let myFont = myFont else { return }
        let dateSize = dateString.size(withAttributes: [NSAttributedString.Key.font: myFont])
        
        // Position in lower right with some padding
        let padding: CGFloat = 10.0
        let x = scaleWidthX - dateSize.width - padding
        let y = bounds.height - dateSize.height - padding
        
        // Draw the date
        dateString.draw(at: CGPoint(x: x, y: y), withAttributes: [
            NSAttributedString.Key.font: myFont,
            NSAttributedString.Key.foregroundColor: UIColor.white
        ])
    }
    
    
    let DOFFST = 15.0

    func drawXAxis(_ context: CGContext?) {
        //var i: Int

        let svOffsetX = graphSV!.contentOffset.x
        let svWidth = graphSV!.contentSize.width
        let secsPerSVX = d(mytogd!.lastDate - mytogd!.firstDate) / svWidth
        let startDate = CGFloat(mytogd!.firstDate) + (svOffsetX * secsPerSVX)
        let finDate = CGFloat(mytogd!.firstDate) + ((svOffsetX + scaleWidthX) * secsPerSVX)

        let dateStep = (finDate - startDate) / XTICKS

        //CGFloat len = self.bounds.size.width - (CGFloat) (2*BORDER);
        let step = (scaleWidthX - (1 * BORDER)) / XTICKS // ignore scaleOrigin as it is 0

        //[self flipCTM:context];

        var nextXt = -2 * DOFFST
        var nextXd = -2 * DOFFST

        for i in 1...Int(XTICKS) {
            var x = CGFloat(d(i) * step)
            var y: CGFloat = 0.0 // self.bounds.size.height - BORDER;
            MoveTo(context!, x, y)
            y += TICKLEN
            AddLineTo(context!, x, y)
            
            y += 1.0 // skip space to time label
            let y2 = y + 4.0 // hack to lengthen ticks where date label can be drawn
            let x2 = x

            let date = Int(startDate + (d(i) * dateStep) + 0.5)

            let sd = Date(timeIntervalSince1970: TimeInterval(date))
            let datestr = DateFormatter.localizedString(
                from: sd,
                dateStyle: .short,
                timeStyle: .short)
            let dta = datestr.components(separatedBy: " ")

            var ds = dta[0]
            let ts = dta[1]

            ds = ds.trimmingCharacters(in: .punctuationCharacters)

            //DBGLog(@"ds= _%@_  ts= _%@_",ds,ts);  // US region gets comma at end of ds

            var dsize: CGSize? = nil
            if let myFont {
                dsize = ds.size(withAttributes: [
                    NSAttributedString.Key.font: myFont
                ])
            }
            var tsize: CGSize? = nil
            if let myFont {
                tsize = ts.size(withAttributes: [
                    NSAttributedString.Key.font: myFont
                ])
            }

            x -= DOFFST
            if (i == 1 || dateStep < 24 * 60 * 60 || Double(i) == XTICKS) && x > nextXt {
                if let myFont {
                    ts.draw(at: CGPoint(x: x, y: y), withAttributes: [
                        NSAttributedString.Key.font: myFont,
                        NSAttributedString.Key.foregroundColor: UIColor.white
                    ])
                }
                nextXt = x + (tsize?.width ?? 0.0)
            }

            y += tsize?.height ?? 0.0 // + 1.0f;
            x -= 15.0
            if (i == 1 || dateStep >= 24 * 60 * 60 || Double(i) == XTICKS) && x > (nextXd + 10.0) {
                if (i != 1) && (Double(i) != XTICKS) {
                    AddLineTo(context!, x2, y2)
                }
                if let myFont {
                    ds.draw(at: CGPoint(x: x, y: y), withAttributes: [
                        NSAttributedString.Key.font: myFont,
                        NSAttributedString.Key.foregroundColor: UIColor.white
                    ])
                }
                nextXd = x + (dsize?.width ?? 0.0)
            }
        }

        context!.strokePath()
        //Stroke
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
