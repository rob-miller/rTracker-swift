//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/

import CoreGraphics
import UIKit
///************
/// gfx.swift
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

/*
 *  gfx.h
 *  rTracker
 *
 *  Created by Rob Miller on 02/02/2011.
 *  Copyright 2011 Robert T. Miller. All rights reserved.
 *
 */


let GFXHDEBUG = 0

func CGPush(_ c: CGContext) {
    c.saveGState()
}
func CGPop(_ c: CGContext){
    c.restoreGState()
}

func MTPrim(_ c: CGContext, _ x: Double, _ y: Double) {
    c.move(to: CGPoint(x: x, y: y))
}
func ALPrim(_ c: CGContext, _ x: Double, _ y: Double) {
    c.addLine(to: CGPoint(x: x, y: y))
}
func AEPrim(_ c: CGContext, _ x: Double, _ y: Double) {
    c.addEllipse(in: CGRect(
        origin: CGPoint(x: x - 2.0, y: y - 2.0),
        size: CGSize(width: 4.0, height: 4.0)
    ))
    c.move(to: CGPoint(x: x, y: y))
}
func AFEPrim(_ c: CGContext, _ x: Double, _ y: Double) {
    c.fillEllipse(in: CGRect(
        origin: CGPoint(x: x - 4.0, y: y - 4.0),
        size: CGSize(width: 8.0, height: 8.0)
    ))
    c.move(to: CGPoint(x: x, y: y))
}
func AE2Prim(_ c: CGContext, _ x: Double, _ y: Double) {
    c.addEllipse(in: CGRect(
        origin: CGPoint(x: x - 3.0, y: y - 3.0),
        size: CGSize(width: 6.0, height: 6.0)
    ))
    c.move(to: CGPoint(x: x, y: y))
}
func ACPrim(_ c: CGContext, _ x: Double, _ y: Double) {
    //CGPush
    c.setLineWidth(2)
    c.setStrokeColor(UIColor.white.cgColor)
    c.move(to: CGPoint(x: x - 8.0, y: y))
    c.addLine(to: CGPoint(x: x + 8.0, y: y))
    c.move(to: CGPoint(x: x, y: y - 8.0))
    c.addLine(to: CGPoint(x: x, y: y + 8.0))
    c.move(to: CGPoint(x: x, y: y))
    c.drawPath(using: .fillStroke)
    //CGPop
}

#if GFXHDEBUG
func MoveTo(_ c: CGContext, _ x: Double, _ y: Double) {
    print("mov: \(x),\(y)")
    MTPrim(c, x, y)
}
func AddLineTo(_ c: CGContext, _ x: Double, _ y: Double) {
    print("lin: \(x),\(y)")
    ALPrim(c, x, y)
}
func AddCircle(_ c: CGContext, _ x: Double, _ y: Double) {
    print("cir: \(x),\(y)")
    AEPrim(c, x, y)
}
func AddFilledCircle(_ c: CGContext, _ x: Double, _ y: Double) {
    print("fcir: \(x),\(y)")
    AFEPrim(c, x, y)
}
func AddCross(_ c: CGContext, _ x: Double, _ y: Double) {
    print("cross: \(x),\(y)")
    ACPrim(c, x, y)
}
func AddBigCircle(_ c: CGContext, _ x: Double, _ y: Double) {
    print("big cir: \(x),\(y)")
    AE2Prim(c, x, y)
}
#else
//#define MoveTo(x,y) CGContextMoveToPoint(context,(x),(y))
//#define AddLineTo(x,y) CGContextAddLineToPoint(context,(x),(y))
//#define AddCircle(x,y) CGContextAddEllipseInRect(context, (CGRect) {{(x-2.0f),(y-2.0f)},{4.0f,4.0f}})
//; CGContextAddEllipseInRect(context, (CGRect) {{(x-1.0f),(y-1.0f)},{2.0f,2.0f}})
func MoveTo(_ c: CGContext, _ x: Double, _ y: Double) {
    MTPrim(c, x, y)
}
func AddLineTo(_ c: CGContext, _ x: Double, _ y: Double) {
    ALPrim(c, x, y)
}
func AddCircle(_ c: CGContext, _ x: Double, _ y: Double) {
    AEPrim(c, x, y)
}
func AddFilledCircle(_ c: CGContext, _ x: Double, _ y: Double) {
    AFEPrim(c, x, y)
}
func AddCross(_ c: CGContext, _ x: Double, _ y: Double) {
    ACPrim(c, x, y)
}
func AddBigCircle(_ c: CGContext, _ x: Double, _ y: Double) {
    AE2Prim(c, x, y)
}
#endif

func DevPt(_ c: CGContext, _ x: Double, _ y: Double) -> CGPoint? {
    c.convertToUserSpace(CGPoint(x: x, y: y))
}
func Stroke(_ c: CGContext) {
    c.strokePath()
}
