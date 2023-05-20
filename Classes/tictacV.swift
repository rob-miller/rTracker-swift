//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// tictac.h
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
//  tictacV.swift
//  rTracker
//
//  Created by Robert Miller on 20/01/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

///************
/// tictacV.swift
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
//  tictacV.swift
//  rTracker
//
//  Created by Robert Miller on 20/01/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

import QuartzCore
import UIKit

// MARK: key singleton access
    var theKey: UInt = 0

class tictacV: UIView {
    /*
     {
    	tObjBase *tob;
    	unsigned int key;
    	int currX;
    	int currY;
    	CGRect currRect;
    //	BOOL flag;
    }*/
    var tob: tObjBase?

    var key: UInt {
        get {
            return theKey
        }
        set(k) {
            DBGLog("setKey: \(theKey) -> \(k)")
            theKey = k
        }
    }
    var currRect = CGRect.zero
    var currX = 0
    var currY = 0
    // region definitions
    var vborder: CGFloat = 0.0
    var hborder: CGFloat = 0.0
    var vlen: CGFloat = 0.0
    var hlen: CGFloat = 0.0
    var vstep: CGFloat = 0.0
    var hstep: CGFloat = 0.0
    // UI element properties 
    var context: CGContext?
    var myFont: UIFont?

    // MARK: core object

    //- (id)initWithFrame:(CGRect)frame {
    //    if ((self = [super initWithFrame:frame])) {
    //        // Initialization code
    //    }
    //    return self;
    //}

    init(pFrame pttf: CGRect) {
        var ttf = pttf
        ttf.origin.x = TICTACHRZFRAC * ttf.size.width
        ttf.origin.y = TICTACVRTFRAC * ttf.size.height
        ttf.size.width *= TICTACWIDFRAC
        ttf.size.height *= TICTACHGTFRAC
        //DBGLog(@"ttv: x=%f y=%f w=%f h=%f",ttf.origin.x,ttf.origin.y,ttf.size.width, ttf.size.height);
        super.init(frame: ttf)
        backgroundColor = .white
        layer.cornerRadius = 8 // doesn't work, probably overwriting rectangle elsewhere
    }

    // MARK: -
    // MARK: draw view

    let TTBF = 0.1
    let TTSF = 0.2667

    func drawTicTac() {
        //var i: Int
        safeDispatchSync({ [self] in
            vborder = TTBF * frame.size.height
            hborder = TTBF * frame.size.width
        })
        vlen = bounds.size.height - (2 * vborder)
        hlen = bounds.size.width - (2 * hborder)
        vstep = bounds.size.height * TTSF
        hstep = bounds.size.width * TTSF

        let context = self.context

        UIColor.green.set()
        MoveTo(context!, hborder, vborder)
        AddLineTo(context!, hborder + hlen, vborder)
        AddLineTo(context!, hborder + hlen, vborder + vlen)
        AddLineTo(context!, hborder, vborder + vlen)
        AddLineTo(context!, hborder, vborder)
        //Stroke

        UIColor.black.set()

        for i in 1...2 {
            // horiz lines
            MoveTo(context!, hborder, vborder + (CGFloat(i) * vstep))
            AddLineTo(context!, hborder + hlen, vborder + (CGFloat(i) * vstep))
        }

        for i in 1...2 {
            // vert lines
            MoveTo(context!, hborder + (CGFloat(i) * hstep), vborder)
            AddLineTo(context!, hborder + (CGFloat(i) * hstep), vborder + vlen)
        }
        //Stroke
    }

    // MARK: bitfuncs to get selected bits from key

    func REGIONMASK(_ x: Int, _ y: Int) -> UInt {
        return ((UInt(0x03)) << (y << 1)) << (x * 2 * 3)
    }
    func REGIONINC(_ x: Int, _ y: Int) -> UInt {
        return ((UInt(0x01)) << (y << 1)) << (x * 2 * 3)
    }
    func REGIONVAL(_ v: UInt, _ x: Int, _ y: Int) -> UInt {
        return ((v & REGIONMASK(x, y)) >> (y << 1)) >> (x * 2 * 3)
    }

    // MARK: translate tic-tac-toe regions to view coords upper left corner

    func tt2vc() -> CGPoint {
        var ret = CGPoint(x: 0.0, y: 0.0)
        ret.x = hborder + (CGFloat(currX) * hstep)
        ret.y = vborder + (CGFloat(currY) * vstep)
        //ret.size.width = self.hstep;
        //ret.size.height = self.vstep;

        return ret
    }

    // MARK: draw current state

    func drawBlank() {
        UIColor.white.set()
        context?.fill(currRect)
        //self.layer.cornerRadius = 8;


    }

    func sDraw(_ str: String?) {

        //[str drawAtPoint:self.currRect.origin withFont:myFont];
        //[str drawInRect:self.currRect withFont:self.myFont lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];

        let paragraphStyle = NSMutableParagraphStyle.default as? NSMutableParagraphStyle
        paragraphStyle?.lineBreakMode = .byClipping
        paragraphStyle?.alignment = .center

        if let myFont, let paragraphStyle {
            str?.draw(in: currRect, withAttributes: [
                NSAttributedString.Key.font: myFont,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ])
        }
    }

    func setCurrPt(_ x: Int, y: Int) {
        var rect: CGRect = CGRect.zero
        currX = x
        currY = y
        rect.origin = tt2vc()
        rect.size.width = hstep
        rect.size.height = vstep
        currRect = rect
        //DBGLog(@"currPt: %d %d",x,y);
    }

    func setNoCurrPt() {
        //DBGLog(@"no curr pt");
        currX = -1
        currY = -1
    }

    func currPt() -> Bool {
        return currX > -1
    }

    func drawCell() {
        drawBlank()
        UIColor.black.set()
        switch REGIONVAL(key, currX, currY) {
        case 0x00:
            //DBGLog(@"00");
            break
        case 0x01:
            //DBGLog(@"01");
            sDraw("X")
        case 0x02:
            //DBGLog(@"10");
            sDraw("O")
        case 0x03:
            //DBGLog(@"11");
            sDraw("+")
        default:
            dbgNSAssert(false, "drawCell bad region val")
        }
    }

    func updateTT() {
        //	if ([self currPt]) {
        //		DBGLog(@"updateTT: draw cell %d %d",self.currX,self.currY);
        //		[self drawCell];
        //	} else {  
        //var i: Int
        //var j: Int
        //DBGLog(@"updateTT: draw all cells");
        for i in 0..<3 {
            for j in 0..<3 {
                setCurrPt(i, y: j)
                drawCell()
            }
        }
        //	}
        setNoCurrPt()
    }

    // MARK: handle region press

    func press(_ x: Int, y: Int) {
        setCurrPt(x, y: y)
        DBGLog(String("press: (x),(y) => (currRect.origin.x) (currRect.origin.y) (currRect.size.width) (currRect.size.height)"))

        //unsigned int rmask = REGIONMASK(x,y);
        //unsigned int rinc =  REGIONINC(x,y);
        var newVal = key // copy current key
        var currBits = newVal & REGIONMASK(x, y) // select bits for this press
        currBits += REGIONINC(x, y) // inc state
        currBits &= REGIONMASK(x, y) // wipe overflow 0x3-> 0x4 0b0011 -> 0b0100
        newVal &= ~REGIONMASK(x, y) // clear bits in current key
        newVal |= currBits // set new bits

        key = newVal
        setNeedsDisplay(currRect)
        //[self setNeedsDisplay];
    }

    // MARK: translate view coords to tic-tac-toe regions

    func ttx(_ x: Int) -> Int {
        let i: Int = 0
        for i in 1..<3 {
            if CGFloat(x) < hborder + (CGFloat(i) * hstep) {
                return i - 1
            }
        }
        return i - 1
    }

    func tty(_ y: Int) -> Int {
        let i: Int = 0
        for i in 1..<3 {
            if CGFloat(y) < vborder + (CGFloat(i) * vstep) {
                return i - 1
            }
        }
        return i - 1
    }

    // MARK: api: draw current key

    func showKey(_ k: UInt) {
        key = k //rtm lskdfjasldfjasdlfjksldfkj
        setNeedsDisplay()
    }

    // MARK: -
    // MARK: UIView drawing

    let FONTNAME = "Helvetica-Bold"
    let FONTSIZE = 20

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
     */
    override func draw(_ rect: CGRect) {
        // Drawing code
        context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(1.0)
        context?.setAlpha(1.0)
        myFont = UIFont(name: String(FONTNAME), size: CGFloat(FONTSIZE))
        updateTT()
        drawTicTac()

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchPoint = touch?.location(in: self)
        //DBGLog(@"ttv: I am touched at %f, %f => x:%d y:%d",touchPoint.x, touchPoint.y,[self ttx:touchPoint.x], [self tty:touchPoint.y]);
        press(ttx(Int(touchPoint?.x ?? 0)), y: tty(Int(touchPoint?.y ?? 0)))
        resignFirstResponder()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
