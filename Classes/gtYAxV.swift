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

    let cv0 = "cv\(c0)"
    let cv1 = "cv\(c1)"

    let v0s = (vogd?.vo?.optDict)?[cv0] as? String
    let v1s = (vogd?.vo?.optDict)?[cv1] as? String

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
    DBGLog("c0 %d c1 %d v0s %@ v1s %@ val0 %f val1 %f", c0, c1, v0s, v1s, val0, val1)
    // need results descending, so reverse test outcome
    if val0 < val1 {
        return ComparisonResult.orderedAscending.rawValue
    } else if val0 > val1 {
        return ComparisonResult.orderedDescending.rawValue
    } else {
        return ComparisonResult.orderedSame.rawValue
    }
}

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
    var aVogd: vogd?
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
    }

    //- (void) setBackgroundColor:(UIColor *) col {
    //    DBGLog(@" gtyaxv bg color set to %@", col);
    //}

    func vtChoiceSetColor(_ context: CGContext?, ndx: Int) {
        let cc = "cc\(ndx)"
        let col = ((vogd?.vo?.optDict)?[cc] as? NSNumber)?.intValue ?? 0
        (rTracker_resource.colorSet()?[col] as? UIColor)?.set()
    }

    func drawYAxis(_ context: CGContext?) {
        var i: Int
        let svHeight = graphSV?.contentSize.height ?? 0.0
        let svOffsetY = svHeight - ((graphSV?.frame.size.height ?? 0.0) + (graphSV?.contentOffset.y ?? 0.0))
        let unitsPerSVY = f((vogd?.maxVal ?? 0.0) - (vogd?.minVal ?? 0.0)) / svHeight
        let startUnit = (vogd?.minVal ?? 0.0) + (svOffsetY * unitsPerSVY)
        let finUnit = (vogd?.minVal ?? 0.0) + ((svOffsetY + (graphSV?.frame.size.height ?? 0.0)) * unitsPerSVY)

        let unitStep = (finUnit - startUnit) / YTICKS

        DBGLog(
            "svcofy= %f svoffy= %f  svh= %f min= %f max= %f upsvy= %f scaleh= %f start= %f fin= %f ",
            graphSV?.contentOffset.y,
            svOffsetY,
            svHeight,
            vogd?.minVal,
            vogd?.maxVal,
            unitsPerSVY,
            scaleHeightY,
            startUnit,
            finUnit)

        //CGFloat len = self.bounds.size.height - (CGFloat) (2*BORDER);
        let step = scaleHeightY / YTICKS

        DBGLog(" %f %f %f", scaleHeightY, YTICKS, step)
        let x0 = bounds.size.width
        let x1 = x0 - TICKLEN
        let x2 = x1 - 3.0

        let vtype = vogd?.vo?.vtype ?? 0
        var fmt = "%0.2f"

        /*
            NSArray *choiceMap;

            if (VOT_CHOICE == vtype) {
                choiceMap = [CHOICEARR sortedArrayUsingFunction:choiceCompare context:(void*)self];
            }
             */
        //NSString *vsCopy = nil;

        i = Int(YTICKS)
        while i >= 1 {
            var y = f(i) * step
            MoveTo(x0, y)
            AddLineTo(x1, y)


            let val = startUnit + (f(YTICKS - Double(i)) * unitStep)
            var vstr: String?
            switch vtype {
            case VOT_CHOICE:
                if YTICKS == Double(i) {
                    vstr = ""
                } else {
                    //DBGLog(@"choiceMap: %@",choiceMap);
                    //NSUInteger ndx = (YTICKS-i)-1;

                    //DBGLog(@"i= %d ndx= %lu",i, (unsigned long) ndx);
                    //DBGLog(@"obj= %@",[choiceMap objectAtIndex:ndx]);
                    //DBGLog(@"choice= %d", [ [choiceMap objectAtIndex:ndx] intValue ]);
                    //int choice = [ [choiceMap objectAtIndex:ndx] intValue ];
                    let choice = vogd?.vo?.getChoiceIndex(forValue: "\(val)") ?? 0
                    vtChoiceSetColor(context, ndx: choice)
                    let ch = "c\(choice)"
                    vstr = (vogd?.vo?.optDict)?[ch] as? String
                }
            case VOT_BOOLEAN:
                if 1 == i {
                    vstr = (vogd?.vo?.optDict)?["boolval"] as? String
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
                if ((vogd?.vo?.optDict)?["tbnl"] as? String) == "1" {
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
                    let fnddp = ((vogd?.vo?.optDict)?["fnddp"] as? NSNumber)?.intValue ?? 0
                    fmt = String(format: "%%0.%df", fnddp)
                } else if vtype == VOT_TEXTB {
                    fmt = "%0.1f"
                } else {
                    //figure out sig figs for input data and set format here accordingly?
                    //fmt = @"%0.2f";
                    let numddps = (vogd?.vo?.optDict)?["numddp"] as? String
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
            if let myFont {
                vh = vstr?.size(withAttributes: [
                    NSAttributedString.Key.font: myFont
                ])
            }
            if let myFont {
                vstr?.draw(at: CGPoint(x: x2 - (vh?.width ?? 0.0), y: y - ((vh?.height ?? 0.0) / 1.5)), withAttributes: [
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
                if let myFont, let myGraphColor = vogd.myGraphColor() {
                    vogd.vo?.valueName?.draw(at: CGPoint(x: SPACE5, y: frame.size.height - BORDER), withAttributes: [
                        NSAttributedString.Key.font: myFont,
                        NSAttributedString.Key.foregroundColor: myGraphColor
                    ])
                }
            })
        }
        //[self.vogd.vo.valueName drawAtPoint:(CGPoint) {SPACE5,(self.frame.size.height - BORDER)} withFont:self.myFont];
        UIColor.white.set()

        //Stroke

        // rtm debug
        backgroundColor = .yellow
    }

    override func draw(_ rect: CGRect) {
        // Drawing code
        let context = UIGraphicsGetCurrentContext()
        context?.clear(bounds)
        UIColor.white.set()

        MoveTo(bounds.size.width, scaleOriginY)
        AddLineTo(bounds.size.width, scaleHeightY) // scaleOriginY = 0

        drawYAxis(context)

    }

    // MARK: -
    // MARK: touch support

    func touchReport(_ touches: Set<AnyHashable>?) -> String? {

        #if DEBUGLOG
        let touch = touches?.first as? UITouch
        let touchPoint = touch?.location(in: self)
        return String(format: "touch at %f, %f.  taps= %lu  numTouches= %lu", touchPoint?.x ?? 0.0, touchPoint?.y ?? 0.0, UInt(touch?.tapCount ?? 0), UInt(touches?.count ?? 0))
        #endif
        return ""

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

        let touch = touches.first as? UITouch
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