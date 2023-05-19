//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
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

let CGPush = context?.saveGState()
let CGPop = context?.restoreGState()

func MTPrim(_ x: Any, _ y: Any) -> Void? {
    context?.move(to: CGPoint(x: x, y: y))
}
func ALPrim(_ x: Any, _ y: Any) -> Void? {
    context?.addLine(to: CGPoint(x: x, y: y))
}
func AEPrim(_ x: Any, _ y: Any) {
    context?.addEllipse(in: CGRect(
        origin: CGPoint(x: x - 2.0, y: y - 2.0),
        size: CGSize(width: 4.0, height: 4.0)
    ))
    context?.move(to: CGPoint(x: x, y: y))
}
func AFEPrim(_ x: Any, _ y: Any) {
    context?.fillEllipse(in: CGRect(
        origin: CGPoint(x: x - 4.0, y: y - 4.0),
        size: CGSize(width: 8.0, height: 8.0)
    ))
    context?.move(to: CGPoint(x: x, y: y))
}
func AE2Prim(_ x: Any, _ y: Any) {
    context?.addEllipse(in: CGRect(
        origin: CGPoint(x: x - 3.0, y: y - 3.0),
        size: CGSize(width: 6.0, height: 6.0)
    ))
    context?.move(to: CGPoint(x: x, y: y))
}
func ACPrim(_ x: Any, _ y: Any) {
    //CGPush
    context?.setLineWidth(2)
    context?.setStrokeColor(UIColor.white.cgColor)
    context?.move(to: CGPoint(x: x - 8.0, y: y))
    context?.addLine(to: CGPoint(x: x + 8.0, y: y))
    context?.move(to: CGPoint(x: x, y: y - 8.0))
    context?.addLine(to: CGPoint(x: x, y: y + 8.0))
    context?.move(to: CGPoint(x: x, y: y))
    context?.drawPath(using: .fillStroke)
    //CGPop
}

#if GFXHDEBUG
func MoveTo(_ x: Any, _ y: Any) {
    print("mov: \(x),\(y)")
    MTPrim(x, y)
}
func AddLineTo(_ x: Any, _ y: Any) {
    print("lin: \(x),\(y)")
    ALPrim(x, y)
}
func AddCircle(_ x: Any, _ y: Any) {
    print("cir: \(x),\(y)")
    AEPrim(x, y)
}
func AddFilledCircle(_ x: Any, _ y: Any) {
    print("fcir: \(x),\(y)")
    AFEPrim(x, y)
}
func AddCross(_ x: Any, _ y: Any) {
    print("cross: \(x),\(y)")
    ACPrim(x, y)
}
func AddBigCircle(_ x: Any, _ y: Any) {
    print("big cir: \(x),\(y)")
    AE2Prim(x, y)
}
#else
//#define MoveTo(x,y) CGContextMoveToPoint(context,(x),(y))
//#define AddLineTo(x,y) CGContextAddLineToPoint(context,(x),(y))
//#define AddCircle(x,y) CGContextAddEllipseInRect(context, (CGRect) {{(x-2.0f),(y-2.0f)},{4.0f,4.0f}})
//; CGContextAddEllipseInRect(context, (CGRect) {{(x-1.0f),(y-1.0f)},{2.0f,2.0f}})
func MoveTo(_ x: Any, _ y: Any) {
    MTPrim(x, y)
}
func AddLineTo(_ x: Any, _ y: Any) {
    ALPrim(x, y)
}
func AddCircle(_ x: Any, _ y: Any) {
    AEPrim(x, y)
}
func AddFilledCircle(_ x: Any, _ y: Any) {
    AFEPrim(x, y)
}
func AddCross(_ x: Any, _ y: Any) {
    ACPrim(x, y)
}
func AddBigCircle(_ x: Any, _ y: Any) {
    AE2Prim(x, y)
}
#endif

func DevPt(_ x: Any, _ y: Any) -> CGPoint? {
    context?.convertToUserSpace(CGPoint(x: x, y: y))
}
let Stroke = context?.strokePath()