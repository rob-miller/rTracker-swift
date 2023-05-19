//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// graphTrackerV.swift
/// Copyright 2010-2021 Robert T. Miller
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
//  graphTrackerV.swift
//  rTracker
//
//  Created by Robert Miller on 28/09/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import QuartzCore
import UIKit

let NOXMARK = -1.0
var context = UIGraphicsGetCurrentContext()
var tm = CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: -1.0, tx: 0.0, ty: bounds.size.height)
var touch = touches.first as? UITouch
var touchPoint = touch?.location(in: self)

class graphTrackerV: UIScrollView {
    /*{
    	trackerObj *tracker;
        valueObj *gtvCurrVO;
        BOOL selectedVO;
        BOOL doDrawGraph;
        CGFloat xMark;
        id parentGTVC;
    }*/
    var tracker: trackerObj?
    var gtvCurrVO: valueObj?
    var selectedVO = false
    var doDrawGraph = false
    var xMark: CGFloat = 0.0
    var parentGTVC: Any?
    var searchXpoints: [AnyHashable]?
    //- (void)setTransform:(CGAffineTransform)newValue;

    /*
    -(id)initWithFrame:(CGRect)r
    {
        self = [super initWithFrame:r];
        if(self) {
            CATiledLayer *tempTiledLayer = (CATiledLayer*)self.layer;
            tempTiledLayer.levelsOfDetail = 5;
            tempTiledLayer.levelsOfDetailBias = 2;
            self.opaque=YES;
        }
        return self;
    }
    */

    override init(frame: CGRect) {
        super.init(frame: frame)
        #if USELAYER
        //from scrollview programming guide listing 3-3
        let tempTiledLayer = layer as? CATiledLayer
        tempTiledLayer?.levelsOfDetail = 5
        tempTiledLayer?.levelsOfDetailBias = 2
        #endif
        isOpaque = false
        doDrawGraph = true // rtm dbg
    }

    /*
    - (void)setTransform:(CGAffineTransform)newValue;
    {
        CGAffineTransform constrainedTransform = CGAffineTransformIdentity;
        constrainedTransform.a = newValue.a;
        [super setTransform:constrainedTransform];
    }
    */


    // MARK: -
    // MARK: drawing routines

    func drawBackground(_ context: CGContext?) {
        UIColor.purple.set()
        context?.fill(bounds)

    }

    // note same name call in gtYAxV
    func vtChoiceSetColor(_ vogd: vogd?, context: CGContext?, val: CGFloat) {
        var val = val
        // DBGLog(@"vtChoiceSetColor input %f",val);
        val /= vogd?.vScale ?? 0.0
        val += vogd?.minVal ?? 0.0
        // DBGLog(@"vtChoiceSetColor transformed %f",val);
        let choice = vogd?.vo?.getChoiceIndex(forValue: "\(val)") ?? 0
        let cc = "cc\(choice)"
        let col = ((vogd?.vo?.optDict)?[cc] as? NSNumber)?.intValue ?? 0
        if let colorSet = (rTracker_resource.colorSet()?[col] as? UIColor)?.cgColor {
            context?.setFillColor(colorSet)
        }
        if let colorSet = (rTracker_resource.colorSet()?[col] as? UIColor)?.cgColor {
            context?.setStrokeColor(colorSet)
        }
    }

    let LXNOTSTARTED = -1.0

    func plotVO_lines(_ vogd: vogd?, context: CGContext?, dots: Bool) {

        let e = (vogd?.ydat as NSArray?)?.objectEnumerator()
        let bbox = context?.boundingBoxOfClipPath
        let minX = bbox?.origin.x ?? 0.0
        let maxX = (bbox?.origin.x ?? 0.0) + (bbox?.size.width ?? 0.0)
        let bigger = true

        var going = false
        var lastX = LXNOTSTARTED
        var lastY = LXNOTSTARTED
        var x: CGFloat = 1.0
        var y: CGFloat = 1.0
        for nx in vogd?.xdat ?? [] {
            guard let nx = nx as? NSNumber else {
                continue
            }
            x = CGFloat(nx.floatValue)
            y = CGFloat((e?.nextObject() as? NSNumber)?.floatValue ?? 0.0)
            if going {
                //DBGLog(@"addline %f %f",x,y);
                AddLineTo(x, y)
                if dots {
                    AddCircle(x, y)
                    if selectedVO {
                        AddBigCircle(x, y)
                    }
                }
                if x > maxX {
                    break //going=NO;
                }
            } else {
                // not started yet
                if x < minX {
                    // not started, save current for next time
                    lastX = x
                    lastY = y
                } else {
                    // start drawing
                    if lastX == LXNOTSTARTED {
                        // 1st time through, 1st point needs showing
                        //DBGLog(@"moveto %f %f",x,y);
                        MoveTo(x, y)
                        if dots {
                            AddCircle(x, y)
                            if selectedVO {
                                AddBigCircle(x, y)
                            }
                        }
                    } else {
                        // process starting, need to show lastX plus current
                        MoveTo(lastX, lastY)
                        if dots {
                            AddCircle(lastX, lastY)
                            if selectedVO {
                                AddBigCircle(lastX, lastY)
                            }
                        }
                        AddLineTo(x, y)
                        if dots {
                            AddCircle(x, y)
                            if selectedVO {
                                AddBigCircle(x, y)
                            }
                        }
                    }
                    going = true
                }
            }
        }
        if bigger {
            // only 1 point, have moved there
            AddCircle(x, y)
            AddBigCircle(x, y)
        }

        //Stroke
    }

    /*
    - (void) plotVO_dotsline:(vogd*)vogd context:(CGContextRef)context
    {
    	NSEnumerator *e = [vogd.ydat objectEnumerator];
    	CGRect bbox = CGContextGetClipBoundingBox(context);
    	CGFloat minX = bbox.origin.x;
        CGFloat maxX = bbox.origin.x + bbox.size.width;
        BOOL bigger = ( [vogd.xdat count] < 2 ? 1 : 0 );

    	BOOL going=NO;
        CGFloat lastX=LXNOTSTARTED;
        CGFloat lastY=LXNOTSTARTED;
        CGFloat x=1.0f,y=1.0f;
    	for (NSNumber *nx in vogd.xdat) {
    		x = [nx floatValue];
    		y = [[e nextObject] floatValue];
            if (going) {
                //DBGLog(@"addline %f %f",x,y);
                AddLineTo(x,y);
                //if (self.selectedVO) {
                //    AddFilledCircle(x,y);             // for some reason, filled circle messes up line
                //} else {
                    AddCircle(x,y);
                    if (self.selectedVO)
                        AddBigCircle(x,y);
                //}
                if (x > maxX)
                    break; //going=NO;   // done
            } else {  // not started yet
                if (x < minX) {  // keep processing until start drawing
                    lastX = x;
                    lastY = y;
                } else { // start drawing
                    if (lastX == LXNOTSTARTED) { // 1st time through, 1st point needs showing
                        //DBGLog(@"moveto %f %f",x,y);
                        MoveTo(x,y);
                        //if (self.selectedVO) {
                        //    AddFilledCircle(lastX,lastY);
                        //} else {
                            AddCircle(lastX,lastY);
                            if (self.selectedVO)
                                AddBigCircle(lastX,lastY);
                                //AddFilledCircle(lastX,lastY);
                        //}
                    } else { // past 1st data point, need to show lastX plus current
                        //if (self.selectedVO) {
                        //    MoveTo(lastX, lastY);
                        //    AddFilledCircle(lastX,lastY);
                        //    AddLineTo(x,y);
                        //    AddFilledCircle(x,y);
                        //} else {
                            MoveTo(lastX, lastY);
                            AddCircle(lastX,lastY);
                            if (self.selectedVO)
                                AddBigCircle(lastX,lastY);
                                //AddFilledCircle(lastX,lastY);
                            AddLineTo(x,y);
                            AddCircle(x,y);
                            if (self.selectedVO)
                                AddBigCircle(x,y);
                                //AddFilledCircle(x,y);
                        //}
                    }
                    going=YES;
                } 
            }
    	}
        if (bigger) // only 1 point, have moved there already
            AddBigCircle(x,y);

    	Stroke;
    }
    */

    func plotVO_dots(_ vogd: vogd?, context: CGContext?) {
        let e = (vogd?.ydat as NSArray?)?.objectEnumerator()
        let bbox = context?.boundingBoxOfClipPath
        let minX = bbox?.origin.x ?? 0.0
        let maxX = (bbox?.origin.x ?? 0.0) + (bbox?.size.width ?? 0.0)

        var lastX = LXNOTSTARTED
        var lastY = LXNOTSTARTED
        var going = false
        let bigger = true // need to emphasize 2 points so can't do outside loop

        for nx in vogd?.xdat ?? [] {
            guard let nx = nx as? NSNumber else {
                continue
            }
            let x = CGFloat(nx.floatValue)
            let y = CGFloat((e?.nextObject() as? NSNumber)?.floatValue ?? 0.0)
            if vogd?.vo?.vtype == VOT_CHOICE {
                vtChoiceSetColor(vogd, context: context, val: y)
            }
            if going {
                //DBGLog(@"moveto %f %f",x,y);
                MoveTo(x, y)
                if selectedVO {
                    AddCross(x, y)
                    AddFilledCircle(x, y)
                } else {
                    AddCircle(x, y)
                }
                if bigger && !selectedVO {
                    AddBigCircle(x, y)
                }
                if vogd?.vo?.vtype == VOT_CHOICE {
                    Stroke
                }
                if x > maxX {
                    break
                }
            } else if x < minX {
                // not started yet and keep skipping -- save current for next time
                lastX = x
                lastY = y
            } else {
                // not started yet, start now
                if lastX != LXNOTSTARTED {
                    // past 1st data point, need to show lastX 
                    MoveTo(lastX, lastY)
                    if selectedVO {
                        AddCross(x, y)
                        AddFilledCircle(lastX, lastY)
                    } else {
                        AddCircle(lastX, lastY)
                    }
                    if vogd?.vo?.vtype == VOT_CHOICE {
                        Stroke
                    }
                }
                going = true // going, show current
                MoveTo(x, y)
                if selectedVO {
                    AddCross(x, y)
                    AddFilledCircle(x, y)
                } else {
                    AddCircle(x, y)
                }
                if bigger && !selectedVO {
                    AddBigCircle(x, y)
                }

                if vogd?.vo?.vtype == VOT_CHOICE {
                    Stroke
                }
            }
        }

        //Stroke
    }

    // TODO: enable putting text on graph
    /*
     - complicated by layers and multi-threading
     - works with USELAYERS=0

    - (void) addText:(vogd*)vogd context:(CGContextRef)context x:(CGFloat)x y:(CGFloat)y e:(NSEnumerator*)e {

        x+= 3.0f;
        y+= 3.0f;
        AddLineTo(x,y);
        x+= 3.0f;
        AddLineTo(x, y);
        NSString *str = [e nextObject];
        CGContextShowTextAtPoint(context, x, y, [str UTF8String], [str length]);
        //[str drawAtPoint:(CGPoint) {x,y} withFont:((graphTrackerVC*)self.parentGTVC).myFont];
        //Stroke;
    }
    */

    /* not used
    - (void) plotVO_dotsNoY:(vogd *)vogd context:(CGContextRef)context
    {
    	CGRect bbox = CGContextGetClipBoundingBox(context);
    	CGFloat minX = bbox.origin.x;
        CGFloat maxX = bbox.origin.x + bbox.size.width;

        CGFloat lastX=LXNOTSTARTED;
        CGFloat lastY=LXNOTSTARTED;
        BOOL going=NO;

        / *
    	NSEnumerator *e = [vogd.ydat objectEnumerator];
        BOOL doText=NO;
        if ((VOT_TEXT == vogd.vo.vtype) && (vogd.vo == self.currVO)) {
            doText = YES;
            CGContextSelectFont(context, FONTNAME, FONTSIZE, kCGEncodingMacRoman);
            CGContextSetTextDrawingMode(context, kCGTextFill);
        }
        * /

    	for (NSNumber *nx in vogd.xdat) {
    		CGFloat x = [nx floatValue];
    		CGFloat y = 2.0f; //[[e nextObject] floatValue];
            if (going) {
                //DBGLog(@"moveto %f %f",x,y);
                MoveTo(x,y);
                AddCircle(x,y);
                //if (doText) [self addText:vogd context:context x:x y:y e:e];
                if (x > maxX)
                    break; 
            } else if (x < minX) { // not started yet and keep skipping -- save current for next time
                lastX = x;
                lastY = y;
            } else {              // not started yet, start now
                if (lastX != LXNOTSTARTED) {  // past 1st data point, need to show lastX 
                    MoveTo(lastX,lastY);
                    AddCircle(lastX,lastY);
                    //if (doText) [self addText:vogd context:context x:x y:y e:e];
                }
                going=YES;    // going, show current
                MoveTo(x,y);
                AddCircle(x,y);
                //if (doText) [self addText:vogd context:context x:x y:y e:e];
            }  
        }

    	Stroke;
    }
    */

    func plotVO_bar(_ vogd: vogd?, context: CGContext?, barCount: Int) {
        if vogd?.vo == gtvCurrVO {
            context?.setAlpha(STD_ALPHA)
            context?.setLineWidth(BAR_LINE_WIDTH_SEL)
        } else {
            context?.setAlpha(BAR_ALPHA)
            context?.setLineWidth(BAR_LINE_WIDTH)
        }


        let barStep = BAR_LINE_WIDTH * CGFloat(barCount)

        let e = (vogd?.ydat as NSArray?)?.objectEnumerator()
        let bbox = context?.boundingBoxOfClipPath
        let minX = bbox?.origin.x ?? 0.0
        let maxX = (bbox?.origin.x ?? 0.0) + (bbox?.size.width ?? 0.0) + BAR_LINE_WIDTH

        var lastX = LXNOTSTARTED
        var lastY = LXNOTSTARTED
        var going = false

        for nx in vogd?.xdat ?? [] {
            guard let nx = nx as? NSNumber else {
                continue
            }
            let x = CGFloat(nx.floatValue) + barStep
            let y = CGFloat((e?.nextObject() as? NSNumber)?.floatValue ?? 0.0)
            if vogd?.vo?.vtype == VOT_CHOICE {
                vtChoiceSetColor(vogd, context: context, val: y)
            }

            if going {
                //DBGLog(@"moveto %f %f",x,y);
                MoveTo(x, 0.0)
                AddLineTo(x, y)
                //AddCircle(x,y);
                if vogd?.vo?.vtype == VOT_CHOICE {
                    Stroke
                }
                if x > maxX {
                    break
                }
            } else if x < minX {
                // not started yet and keep skipping -- save current for next time
                lastX = x
                lastY = y
            } else {
                // not started yet, start now
                if lastX != LXNOTSTARTED {
                    // past 1st data point, need to show lastX 
                    MoveTo(lastX, 0.0)
                    AddLineTo(lastX, lastY)
                    //AddCircle(lastX,lastY);
                    if vogd?.vo?.vtype == VOT_CHOICE {
                        Stroke
                    }
                }
                going = true // going, show current
                MoveTo(x, 0.0)
                AddLineTo(x, y)
                //AddCircle(x,y);
                if vogd?.vo?.vtype == VOT_CHOICE {
                    Stroke
                }
            }
        }

        if vogd?.vo?.vtype != VOT_CHOICE {
            Stroke
        }
        //Stroke;

        context?.setAlpha(STD_ALPHA)
        context?.setLineWidth(STD_LINE_WIDTH)

    }

    func plotVO(_ vo: valueObj?, context: CGContext?, barCount: Int) {
        //[(UIColor *) [self.tracker.colorSet objectAtIndex:vo.vcolor] set];

        let currVogd = vo?.vogd as? vogd

        if vo == gtvCurrVO {
            let ylineS = vo?.optDict?["yline1"] as? String
            if ylineS != nil && (ylineS != "") {
                let ylineF = CGFloat(Float(ylineS ?? "") ?? 0.0)
                if ((currVogd?.minVal ?? 0.0) < ylineF) && ((currVogd?.maxVal ?? 0.0) > ylineF) {
                    // draw line at yline if visible
                    let yline = (ylineF * (currVogd?.vScale ?? 0.0)) + (currVogd?.yZero ?? 0.0)
                    context?.setStrokeColor(UIColor(white: 0.90, alpha: 0.8).cgColor)
                    MoveTo(0.0, yline)
                    safeDispatchSync({ [self] in
                        AddLineTo(frame.size.width, yline)
                    })
                    //Stroke
                }
            } else {
                // draw zero line if no Y line spcified
                if ((currVogd?.minVal ?? 0.0) < 0.0) && ((currVogd?.maxVal ?? 0.0) > 0.0) {
                    // draw line at 0 if needed
                    context?.setStrokeColor(UIColor(white: 0.75, alpha: 0.5).cgColor)
                    MoveTo(0.0, currVogd?.yZero)
                    safeDispatchSync({ [self] in
                        AddLineTo(frame.size.width, currVogd?.yZero)
                    })
                    //Stroke
                }
            }

            context?.setLineWidth(DBL_LINE_WIDTH)
            selectedVO = true
        } else {
            context?.setLineWidth(STD_LINE_WIDTH)
            selectedVO = false
        }

        if vo?.vtype != VOT_CHOICE {
            if let colorSet = (rTracker_resource.colorSet()?[vo?.vcolor ?? 0] as? UIColor)?.cgColor {
                context?.setFillColor(colorSet)
            }
            if let colorSet = (rTracker_resource.colorSet()?[vo?.vcolor ?? 0] as? UIColor)?.cgColor {
                context?.setStrokeColor(colorSet)
            }
        }

        switch vo?.vGraphType {
        case VOG_DOTS /* 25.i.14  bool and text/textbox plot as 1 (or boolval) at top of graph */:
            switch vo?.vtype {
            case VOT_NUMBER, VOT_SLIDER, VOT_CHOICE, VOT_FUNC, VOT_BOOLEAN,                 //[self plotVO_dots:currVogd context:context];
                //break;
            VOT_TEXT:
                fallthrough
            default:
                //if ([(NSString*) [vo.optDict objectForKey:@"tbnl"] isEqualToString:@"1"]) { // linecount is a num for graph
                plotVO_dots(currVogd, context: context)
                //} else {
                //    [self plotVO_dotsNoY:currVogd context:context];
                //}
            }
        case VOG_BAR:
            plotVO_bar(currVogd, context: context, barCount: barCount)
        case VOG_LINE:
            plotVO_lines(currVogd, context: context, dots: false)
        case VOG_DOTSLINE:
            //[self plotVO_dotsline:currVogd context:context];
            plotVO_lines(currVogd, context: context, dots: true)
        case VOG_PIE:
            DBGErr("pie chart not yet supported")
        case VOG_NONE /* nothing to do! */:
            break
        default:
            DBGErr("plotVO: vGraphType %ld not recognised", Int(vo?.vGraphType ?? 0))
        }
    }

    func drawGraph(_ context: CGContext?) {
        //DBGLog(@"drawGraph");
        var barCount = 0
        for vo in tracker?.valObjTable ?? [] {
            guard let vo = vo as? valueObj else {
                continue
            }
            if (vo.optDict)?["graph"] != "0" {
                if VOG_BAR == vo.vGraphType {
                    barCount += 1
                }
            }
        }
        barCount /= -2

        for vo in tracker?.valObjTable ?? [] {
            guard let vo = vo as? valueObj else {
                continue
            }
            if vo != gtvCurrVO {
                if (vo.optDict)?["graph"] != "0" {
                    //DBGLog(@"drawGraph %@",vo.valueName);
                    plotVO(vo, context: context, barCount: barCount)
                    if VOG_BAR == vo.vGraphType {
                        barCount += 1
                    }
                }
            }
        }
        // plot selected last for best hightlight
        if (gtvCurrVO?.optDict)?["graph"] != "0" {
            //DBGLog(@"drawGraph %@",vo.valueName);
            plotVO(gtvCurrVO, context: context, barCount: barCount)
            if VOG_BAR == gtvCurrVO?.vGraphType {
                barCount += 1
            }
        }

        if xMark != NOXMARK {
            context?.setFillColor(UIColor.white.cgColor)
            context?.setStrokeColor(UIColor.white.cgColor)
            MoveTo(xMark, 0.0)
            safeDispatchSync({ [self] in
                AddLineTo(xMark, frame.size.height)
            })
            //Stroke
        }
        if let searchXpoints {
            //UIColor *smColor = [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:0.7];
            let smColor = UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1.0)
            context?.setFillColor(smColor.cgColor)
            context?.setStrokeColor(smColor.cgColor)

            context?.setLineWidth(SRCH_LINE_WIDTH)
            let lengths = [3.0, 3.0]
            context?.setLineDash(phase: 0.0, lengths: lengths)

            for xm in searchXpoints {
                guard let xm = xm as? NSNumber else {
                    continue
                }
                MoveTo(xm.floatValue, 0.0)
                safeDispatchSync({ [self] in
                    AddLineTo(xm.floatValue, frame.size.height)
                })
                //Stroke
            }

            context?.setLineDash(phase: 0.0, lengths: nil)
        }
    }

    // MARK: -
    // MARK: drawRect


    // using layers is a tiled approach, speedup realized because only needed tiles are redrawn.  plotVO_ routines work out if data in tiles.
    #if USELAYER

    override class var layerClass: AnyClass {
        return CATiledLayer.self
    }

    // Implement -drawRect: so that the UIView class works correctly
    // Real drawing work is done in -drawLayer:inContext
    override func draw(_ r: CGRect) {
        //    self.context = UIGraphicsGetCurrentContext();
        //    [self drawLayer:self.layer inContext:self.context];
    }

    /// multi-threaded !!!!
    override func draw(_ layer: CALayer, in context: CGContext) {
        //NSLog(@"drawLayer here...");

        //- (void)drawRect:(CGRect)rect {
        //((togd*)self.tracker.togd).bbox = CGContextGetClipBoundingBox(context);
        #else
        -
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

//#import "togd.h"

//#define DEBUGLOG 1


// use layers to get satisfactory resolution for CGContext drawing after zooming
let USELAYER = 1

//DBGLog(@"doDrawGraph is true, gtvCurrVo= %@",self.gtvCurrVO.valueName);
/*
        if ((CGContextRef)0 == inContext) {
            self.context = UIGraphicsGetCurrentContext();
        } else {
            self.context = inContext;
        }
         */
//CGContextSetLineWidth(context, STD_LINE_WIDTH);
func CGContextSetAlpha(_ context: Int, _ STD_ALPHA: Int) {
}

// transform y to origin at lower left ( -y + height )
// scale x to date range -- unfortunately buggered because line width is in user coords applied to both x and y
//CGAffineTransform tm = { ((self.bounds.size.width - 2.0f*BORDER) / (lastDate - firstDate)) , 0.0f, 0.0f, -1.0f, 0.0f, self.bounds.size.height };
func CGContextConcatCTM(_ context: Int, _ tm: Int) {
}

// MARK: -
// MARK: touch support

#if DEBUGLOG
//return @"";
#endif
/*
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    DBGLog(@"touches began: %@", [self touchReport:touches]);
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    DBGLog(@"touches cancelled: %@", [self touchReport:touches]);
}
*///DBGLog(@"touches ended: %@", [self touchReport:touches]);

/*
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    DBGLog(@"touches moved: %@", [self touchReport:touches]);
}
*/