//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// gtYAxV.swift
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
//  gtYAxV.swift
//  rTracker
//
//  Created by Rob Miller on 12/05/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

import UIKit
/*
func intSort(_ num1: Any?, _ num2: Any?, _ context: UnsafeMutableRawPointer?) -> Int {
    let v1 = (num1 as? NSNumber)?.intValue ?? 0
    let v2 = (num2 as? NSNumber)?.intValue ?? 0
    if v1 < v2 {
        return ComparisonResult.orderedAscending.rawValue
    } else if v1 > v2 {
        return ComparisonResult.orderedDescending.rawValue
    } else {
        return ComparisonResult.orderedSame.rawValue
    }
}

func choiceCompare(_ ndx0: Any?, _ ndx1: Any?, _ context: UnsafeMutableRawPointer?) -> Int {
    let c0 = (ndx0 as? NSNumber)?.intValue ?? 0
    let c1 = (ndx1 as? NSNumber)?.intValue ?? 0

    let self = context as? gtYAxV

    let cv0 = String("cv\(c0)")
    let cv1 = String("cv\(c1)")

    let v0s = vogd!.vo.optDict[cv0]
    let v1s = vogd!.vo.optDict[cv1]

    if (nil == v0s) || (nil == v1s) {
        // push not-set choices to top of graph
        if v1s != nil {
            return ComparisonResult.orderedDescending.rawValue
        } else if v0s != nil {
            return ComparisonResult.orderedAscending.rawValue
        } else {
            return ComparisonResult.orderedSame.rawValue
        }
    }

    let val0 = CGFloat(Float(v0s ?? "") ?? 0.0)
    let val1 = CGFloat(Float(v1s ?? "") ?? 0.0)
    DBGLog(String("c0 \(c0) c1 \(c1) v0s \(v0s) v1s \(v1s) val0 \(val0) val1 \(val1)"))
    // need results descending, so reverse test outcome
    if val0 < val1 {
        return ComparisonResult.orderedAscending.rawValue
    } else if val0 > val1 {
        return ComparisonResult.orderedDescending.rawValue
    } else {
        return ComparisonResult.orderedSame.rawValue
    }
}
*/

class gtYAxV: UIView {
    /*{
        vogd *vogd;
        UIFont *myFont;
        CGFloat scaleOriginY;
        CGFloat scaleHeightY;
        UIScrollView *graphSV;

        id parentGTVC;
    }*/

    //@property(nonatomic,retain) UIColor *backgroundColor;
    var vogd: vogd?
    var myFont: UIFont?
    var scaleOriginY: CGFloat = 0.0
    var scaleHeightY: CGFloat = 0.0
    var graphSV: UIScrollView?
    var parentGTVC: Any?

 //, backgroundColor;
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Initialization code
        // rtm debug
        //[self setBackgroundColor:[UIColor yellowColor]];
        //self.backgroundColor = [UIColor yellowColor];
        //self.opaque = YES;
        //self.alpha = 1.0f;

        //DBGLog(@"gtyaxv init done");
        accessibilityIdentifier = "gtYAxV"
    }

    //- (void) setBackgroundColor:(UIColor *) col {
    //    DBGLog(@" gtyaxv bg color set to %@", col);
    //}

    func vtChoiceSetColor(_ context: CGContext?, ndx: Int) {
        let cc = "cc\(ndx)"
        let col = Int(vogd!.vo.optDict[cc] ?? "") ?? 0 // rtmx
        rTracker_resource.colorSet()[col].set()
    }

    func drawYAxis(_ context: CGContext) {
        var i: Int
        let svHeight = graphSV!.contentSize.height
        let svOffsetY = svHeight - (graphSV!.frame.size.height + graphSV!.contentOffset.y)
        let unitsPerSVY = d(vogd!.maxVal - vogd!.minVal) / svHeight
        
        let vtype = vogd?.vo.vtype ?? 0

        
        let startUnit = (vogd?.minVal ?? 0.0) + (svOffsetY * unitsPerSVY)
        let finUnit = (vogd?.minVal ?? 0.0) + ((svOffsetY + (graphSV?.frame.size.height ?? 0.0)) * unitsPerSVY)

        let unitStep = (finUnit - startUnit) / YTICKS

        DBGLog(
            String("svcofy= \(graphSV?.contentOffset.y) svoffy= \(svOffsetY) svh= \(svHeight) min= \(vogd!.minVal) max= \(vogd?.maxVal) upsvy= \(unitsPerSVY) scaleh= \(scaleHeightY) start= \(startUnit) fin= \(finUnit)"))

        //CGFloat len = self.bounds.size.height - (CGFloat) (2*BORDER);
        let step = scaleHeightY / YTICKS

        DBGLog(String(" \(scaleHeightY) \(YTICKS) \(step)"))
        let x0 = bounds.size.width
        let x1 = x0 - TICKLEN
        let x2 = x1 - 3.0

        var fmt = "%0.2f"
        
        var choiceMap: [Int: Int] = [:]
        if VOT_CHOICE == vtype {
            var deltaMap: [Int:Double] = [:]
            var valMap: [Int:Double] = [:]
            for i in 1...Int(YTICKS) {
                let val = startUnit + (d(YTICKS - Double(i)) * unitStep)
                let chc = vogd?.vo.getChoiceIndex(forValue: "\(val)") ?? 0
                let chcVal = Double(vogd?.vo.optDict["cv\(chc)"] ?? "") ?? Double(i+1)
                choiceMap[i] = chc
                valMap[i] = val
                deltaMap[i] = abs(chcVal - val)
            }
            
            var delSet: Set<Int> = []
            // don't have any choices duplicated
            for (ndx, chc) in choiceMap {
                for (ndx2, chc2) in choiceMap {
                    if ndx != ndx2 && chc == chc2 {
                        if deltaMap[ndx2]! < deltaMap[ndx]! {
                            delSet.insert(ndx)
                        }
                    }
                }
                // don't have any undefined chnoices
                if vogd?.vo.optDict["c\(chc)"] == nil {
                    delSet.insert(ndx)
                }
            }
            for i in delSet {
                choiceMap[i] = nil
            }

            /*
            // don't miss any choices ... not working
            var addSet: Set<Int> = []
            for i in 0..<vogd!.choiceCount {
                var missed = true
                for (_, chc) in choiceMap {
                    if i == chc {
                        missed = false
                        break
                    }
                }
                if missed {
                    print("missed \(i)  \(vogd!.vo.optDict["c\(i)"]!)")
                    addSet.insert(i)
                }
            }

            for newChoice in addSet {
                let newValue = Double(vogd?.vo.optDict["cv\(newChoice)"] ?? "") ?? Double(newChoice+1)
                // Find the position to insert the new value
                let insertPosition = valMap.first(where: { $0.value >= newValue })?.key ?? choiceMap.count

                // Shift the elements from the end to the insert position
                for i in stride(from: choiceMap.keys.max() ?? 0, to: insertPosition - 1, by: -1) {
                    choiceMap[i + 1] = choiceMap[i]
                }

                // Insert the new value
                choiceMap[insertPosition] = newChoice

                //print(dict) // Result: [2: 3, 4: 4, 0: 1, 5: 6, 1: 2, 3: 5]

            }
             */
        }

        i = Int(YTICKS)
        while i >= 1 {
            var y = d(i) * step
            MoveTo(context, x0, y)
            AddLineTo(context, x1, y)
            context.strokePath()

            let val = startUnit + (d(YTICKS - Double(i)) * unitStep)
            var vstr: String?
            switch vtype {
            case VOT_CHOICE:
                //if YTICKS == Double(i) {
                //    vstr = ""
                //} else {

                    if let choice = choiceMap[i] {  // vogd?.vo.getChoiceIndex(forValue: "\(val)") ?? 0
                        vtChoiceSetColor(context, ndx: choice)
                        let ch = "c\(choice)"
                        vstr = vogd?.vo.optDict[ch] as? String
                        DBGLog("i= \(i) ch= \(ch)  vstr= \(vstr!) val= \(val)")
                    } else {
                        vstr = ""
                    }
                //}
                /*
                let choice = choiceMap[i]  // vogd?.vo.getChoiceIndex(forValue: "\(val)") ?? 0
                if let choice {
                    vtChoiceSetColor(context, ndx: choice!)
                    let ch = "c\(choice!)"
                    vstr = vogd?.vo.optDict[ch] as? String
                    DBGLog("i= \(i) ch= \(ch)  vstr= \(vstr!) val= \(val)")
                } else {
                    vstr = ""
                }

                //}
                 */
            case VOT_BOOLEAN:
                if 1 == i {
                    vstr = (vogd?.vo.optDict)?["boolval"] as? String
                    y = 0.2 * step
                } else {
                    vstr = ""
                }
            case VOT_TEXT:
                //case VOT_IMAGE:
                if 1 == i {
                    vstr = "1"
                    y = 0.2 * step
                } else {
                    vstr = ""
                }
            case VOT_TEXTB:
                if (vogd?.vo.optDict["tbnl"] as? String) == "1" {
                    // linecount is a num for graph
                    // fall through to default - handle as number
                } else if 1 == i {
                    vstr = "1"
                    y = 0.2 * step
                } else {
                    vstr = ""
                }
            //case VOT_NUMBER:
            //case VOT_SLIDER:
            //case VOT_FUNC:

            default:
                if vtype == VOT_FUNC {
                    let fnddp = Int((vogd?.vo.optDict["fnddp"]) ?? "")
                    fmt = String("%0.\(fnddp ?? 0)f")
                } else if vtype == VOT_TEXTB {
                    fmt = "%0.1f"
                } else {
                    //figure out sig figs for input data and set format here accordingly?
                    //fmt = @"%0.2f";
                    let numddps = vogd?.vo.optDict["numddp"] as? String
                    let numddp = Int(numddps ?? "") ?? 0
                    if (nil == numddps) || (-1 == numddp) {
                        if unitStep < 1.0 {
                            fmt = "%0.2f"
                        } else if unitStep < 2.0 {
                            fmt = "%0.1f"
                        } else {
                            fmt = "%0.0f"
                        }
                    } else {
                        fmt = String(format: "%%0.%df", numddp)
                    }
                }

                vstr = String(format: fmt, val)


                //if ([vstr isEqualToString:vsCopy])
                //    vstr = nil;  // just do once, tho could do better at getting closer to actual value
                //else
                //    vsCopy = vstr;
            }
            //CGSize vh = [vstr sizeWithFont:self.myFont];
            //[vstr drawAtPoint:(CGPoint) {(x2 - vh.width ),(y - (vh.height/1.5f))} withFont:self.myFont];

            var vh: CGSize? = nil
            if let myFont, let vstr {
                vh = vstr.size(withAttributes: [
                    NSAttributedString.Key.font: myFont
                ])

                vstr.draw(at: CGPoint(x: x2 - (vh?.width ?? 0.0), y: y - ((vh?.height ?? 0.0) / 1.5)), withAttributes: [
                    NSAttributedString.Key.font: myFont,
                    NSAttributedString.Key.foregroundColor: UIColor.white
                ])
            }
            i -= 1
        }

        //[[self.vogd myGraphColor] set];  dictionaryWithObjects
        if let vogd {
            // can get here with no graph data if only vot_info entries
            safeDispatchSync({ [self] in
                if let myFont {
                    let myGraphColor = vogd.myGraphColor()

                    // Save the current graphics context
                    if let context = UIGraphicsGetCurrentContext() {
                        context.saveGState()

                        // Translate and rotate the context
                        context.translateBy(x: 0, y: frame.size.height)
                        context.rotate(by: -(.pi / 2)) // 90 degrees counterclockwise

                        // Draw the string
                        let attributes: [NSAttributedString.Key: Any] = [
                            .font: myFont,
                            .foregroundColor: myGraphColor
                        ]
                        
                        // Note: The position might need to be adjusted based on your layout
                        let textPosition = CGPoint(x: 5 * SPACE5, y: BORDER/2)
                        vogd.vo.valueName?.draw(at: textPosition, withAttributes: attributes)

                        // Restore the graphics context
                        context.restoreGState()
                    }
                }
                /*
                if let myFont {
                    let myGraphColor = vogd.myGraphColor()
                    vogd.vo.valueName?.draw(at: CGPoint(x: 3 * SPACE5, y: frame.size.height - BORDER), withAttributes: [
                        NSAttributedString.Key.font: myFont,
                        NSAttributedString.Key.foregroundColor: myGraphColor
                    ])
                }
                 */
            })
        }
        //[self.vogd.vo.valueName drawAtPoint:(CGPoint) {SPACE5,(self.frame.size.height - BORDER)} withFont:self.myFont];
        UIColor.white.set()

        //Stroke
        context.strokePath()
        // rtm debug
        //backgroundColor = .yellow
    }

    override func draw(_ rect: CGRect) {
        // Drawing code
        let context = UIGraphicsGetCurrentContext()!
        context.clear(bounds)
        UIColor.white.set()

        MoveTo(context, bounds.size.width, scaleOriginY)
        AddLineTo(context, bounds.size.width, scaleHeightY) // scaleOriginY = 0

        drawYAxis(context)

    }

    // MARK: -
    // MARK: touch support

    func touchReport(_ touches: Set<AnyHashable>?) -> String {
        var str: String = ""
        #if DEBUGLOG
        let touch = touches?.first as? UITouch
        let touchPoint = touch?.location(in: self)
        str = String(format: "touch at %f, %f.  taps= %lu  numTouches= %lu", touchPoint?.x ?? 0.0, touchPoint?.y ?? 0.0, UInt(touch?.tapCount ?? 0), UInt(touches?.count ?? 0))
        #endif
        return str
    }

    /*
    - (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
        DBGLog(@"gvc touches began: %@", [self touchReport:touches]);
    }

    - (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
        DBGLog(@"gvc touches cancelled: %@", [self touchReport:touches]);
    }
    */

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //DBGLog(@"gvc touches ended: %@", [self touchReport:touches]);

        let touch = touches.first
        if (1 == touch?.tapCount) && (1 == touches.count) {
            (parentGTVC as? graphTrackerVC)?.yavTap()
        }

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    /*
    - (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
        DBGLog(@"gvc touches moved: %@", [self touchReport:touches]);
    }
    */
}
