//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// gtVONameV.swift
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
//  gtVONameV.swift
//  rTracker
//
//  Created by Rob Miller on 12/05/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

import UIKit

class gtVONameV: UIView {
    /*{
        valueObj *currVO;
        UIFont *myFont;
        UIColor *voColor;
    }*/
    var currVO: valueObj?
    var myFont: UIFont?
    var voColor: UIColor?

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Initialization code
        // rtm debug
        //[self setBackgroundColor:[UIColor purpleColor]];
    }

    // TODO: clean up / eliminate flipCTM calls
    func flipCTM(_ context: CGContext?) {
        let tm = CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: -1.0, tx: 0.0, ty: bounds.size.height)
        context?.concatenate(tm)
    }

    func drawCVOnextBtn(_ context: CGContext?) {
        var tsize: CGSize? = nil
        if let myFont {
            tsize = "N".size(withAttributes: [
                NSAttributedString.Key.font: myFont
            ])
        } // only need height
        var tpos = CGPoint(x: bounds.size.width - (tsize?.width ?? 0.0), y: (tsize?.height ?? 0.0) / 2.0) // right side
        if tpos.y > bounds.size.height {
            tpos.y = bounds.size.height
        }

        flipCTM(context)
        if let myFont {
            "N".draw(at: tpos, withAttributes: [
                NSAttributedString.Key.font: myFont,
                NSAttributedString.Key.foregroundColor: UIColor.white
            ])
        }
        flipCTM(context)
    }

    func drawCVOrefreshBtn(_ context: CGContext?) {
        var tsize: CGSize? = nil
        if let myFont {
            tsize = "R".size(withAttributes: [
                NSAttributedString.Key.font: myFont
            ])
        } // only need height
        var tpos = CGPoint(x: bounds.size.width - (2.0 * (tsize?.width ?? 0.0)), y: (tsize?.height ?? 0.0) / 2.0) // right side, 1 width in
        if tpos.y > bounds.size.height {
            tpos.y = bounds.size.height
        }

        flipCTM(context)
        if let myFont {
            "R".draw(at: tpos, withAttributes: [
                NSAttributedString.Key.font: myFont,
                NSAttributedString.Key.foregroundColor: UIColor.white
            ])
        }
        flipCTM(context)
    }

    func drawCVOName(_ context: CGContext?) {
        var tsize: CGSize? = nil
        if let myFont {
            tsize = currVO?.valueName?.size(withAttributes: [
                NSAttributedString.Key.font: myFont
            ])
        }
        var tpos = CGPoint(x: 0.0, y: (bounds.size.height - (tsize?.height ?? 0.0)) / 2.0) // left side of view for vo name
        //CGPoint tpos = { ((self.bounds.size.width/2.0f) - tsize.width)/2.0f,((BORDER - tsize.height)/2.0f) };  // center left half
        //if (tpos.x < 0) 
        //	tpos.x=0;
        if tpos.y > bounds.size.height {
            tpos.y = bounds.size.height
        }

        flipCTM(context)
        if let myFont {
            currVO?.valueName?.draw(at: tpos, withAttributes: [
                NSAttributedString.Key.font: myFont,
                NSAttributedString.Key.foregroundColor: UIColor.white
            ])
        }
        flipCTM(context)
    }

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        voColor?.set()

        drawCVOName(context)
        drawCVOnextBtn(context)
    }

    // MARK: -
    // MARK: touch support

    func touchReport(_ touches: Set<AnyHashable>?) -> String? {
        var str: String = ""
        #if DEBUGLOG
        let touch = touches?.first as? UITouch
        let touchPoint = touch?.location(in: self)
        str = String(format: "touch at %f, %f.  taps= %lu  numTouches= %lu", touchPoint?.x ?? 0.0, touchPoint?.y ?? 0.0, UInt(touch?.tapCount ?? 0), UInt(touches?.count ?? 0))
        #endif
        return str

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        DBGLog(String("gvc touches began: \(touchReport(touches))"))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        DBGLog(String("gvc touches cancelled: \(touchReport(touches))"))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        DBGLog(String("gvc touches ended: \(touchReport(touches))"))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        DBGLog(String("gvc touches moved: \(touchReport(touches))"))
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

//TODO: is this used???
