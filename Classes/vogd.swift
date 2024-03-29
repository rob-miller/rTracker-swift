//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// vogd.swift
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
//  vogd.swift
//
//  Value Object Graph Data
//
//  rTracker
//
//  Created by Rob Miller on 10/05/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

import Foundation

class vogd: NSObject {
    /*{
        valueObj *vo;
        NSArray *xdat;
        NSArray *ydat;

        double minVal;
        double maxVal;

        double vScale;

        CGFloat yZero;
    }*/
    var vo: valueObj
    var xdat: [AnyHashable]?
    var ydat: [AnyHashable]?
    var minVal = 0.0
    var maxVal = 0.0
    var vScale = 0.0
    var yZero: CGFloat = 0.0
    var choiceCount = 0

    
    init(_ inVO: valueObj) {
        vo = inVO
        super.init()
        //DBGErr("vogd: invalid init!")

    }

    func getMinMax(_ targ: String, alt: String?) -> Double {
        if let alt {
            let scanner = Scanner(string: alt)
            if let retval = scanner.scanDouble() {
                return retval
            }
        }
        let myTracker = vo.parentTracker
        let myTOGD = myTracker.togd!
        let sql = String(format: "select %@(val collate CMPSTRDBL) from voData where id=%ld and val != '' and date >= %d and date <= %d;", targ, Int(vo.vid), myTOGD.firstDate, myTOGD.lastDate)
        return myTracker.toQry2Double(sql:sql) ?? 0.0
    }

    func initAsNum(_ inVO: valueObj) -> vogd {
        //super.init()
        vo = inVO
        yZero = 0.0

        //double dscale = d(self.bounds.size.width - (2.0f*BORDER)) / d(self.lastDate - self.firstDate);

        let myTracker = vo.parentTracker
        let myTOGD = myTracker.togd!

        if (vo.vtype == VOT_NUMBER || vo.vtype == VOT_FUNC) && ("0" == vo.optDict["autoscale"]) {
            // override autoscale if needed
            if let gminStr = vo.optDict["gmin"],
               let gmaxStr = vo.optDict["gmax"],
               let gmin = Double(gminStr),
               let gmax = Double(gmaxStr) {
                if gmin == gmax {  // both set and equal then override
                    vo.optDict["autoscale"] = "1"
                }
            } else {  // not both set then override
                vo.optDict["autoscale"] = "1"
            }
        }
        if (vo.vtype == VOT_NUMBER || vo.vtype == VOT_FUNC) && ("0" == vo.optDict["autoscale"]) {
            //DBGLog(@"autoscale= %@", [self.vo.optDict objectForKey:@"autoscale"]);
            minVal = getMinMax("min", alt: (vo.optDict["gmin"])!)
            maxVal = getMinMax("max", alt: (vo.optDict["gmax"])!)
        } else if vo.vtype == VOT_SLIDER {
            minVal = Double((vo.optDict)["smin", default:String("\(SLIDRMINDFLT)")])!
            maxVal = Double((vo.optDict)["smax", default:String("\(SLIDRMAXDFLT)")])!
        } else if vo.vtype == VOT_BOOLEAN {
            let offVal = 0.0
            let onVal = Double((vo.optDict["boolval", default:"0.0"]))!
            if offVal < onVal {
                minVal = offVal
                maxVal = onVal
            } else {
                minVal = onVal
                maxVal = offVal
            }
        } else if vo.vtype == VOT_CHOICE {
            minVal = d(0)
            maxVal = d(0)
            choiceCount = 0
            var c = 0
            for i in 0..<CHOICES {
                var tval:Double? = nil
                let key = "cv\(i)"
                let tstVal = vo.optDict[key]
                let skey = "c\(i)"
                let tstStr = vo.optDict[skey]
                if let tstVal {
                    // only do specified choice values
                    c += 1
                    tval = Double(tstVal) ?? 0.0
                } else if tstStr != nil && "" != tstStr {
                    c += 1
                    tval = Double(i)
                }
                if let tval {
                    if minVal > tval {
                        minVal = tval
                    }
                    if maxVal < tval {
                        maxVal = tval
                    }
                }
            }
            choiceCount = c
            if minVal == maxVal {
                // if no cv values set above, default to choice numbers
                // should not happen
                minVal = d(1)
                maxVal = d(choiceCount)  // CHOICES
            }
            #if GRAPHDBG
            DBGLog(String("choice minVal= \(minVal) maxVal= \(maxVal)"))
            #endif

            /*
            let step = (maxVal - minVal) / Double(choiceCount-1) //  CHOICES;
            minVal -= step //( d( YTICKS - CHOICES ) /2.0 ) * step;   // YTICKS=7, CHOICES=6, so need blank positions at top and bottom
            maxVal += step // d(YTICKS - Double(choiceCount-1)) // step ; //( d( YTICKS - CHOICES ) /2.0 ) * step;
            */
             
            #if GRAPHDBG
            //DBGLog(String("\(inVO.valueName) minVal= \(minVal) maxVal= \(maxVal) step = \(step)"))
            //DBGLog("Foo");
            #endif
        } else {
            // number or function with autoscale

            minVal = getMinMax("min", alt: nil)
            maxVal = getMinMax("max", alt: nil)

            /*
                        // should be option ASFROMZERO
                        if ((0.0f < self.minVal) && (0.0f < self.maxVal)) {   // confusing if no start at 0
                            self.minVal = 0.0f;
                        }
                        */
        }

        if minVal == maxVal {
            minVal = 0.0
        }
        if minVal == maxVal {
            maxVal = 1.0
        }

        if VOT_CHOICE != vo.vtype {
            let yScaleExpand = (maxVal - minVal) * GRAPHSCALE
            if nil == vo.optDict["gmax"] || "" == vo.optDict["gmax"] {
                maxVal += yScaleExpand // +5% each way for visibility unless specified
            }
            if nil == vo.optDict["gmin"] || "" == vo.optDict["gmin"] {
                minVal -= yScaleExpand
            }
        }
        #if GRAPHDBG
        DBGLog(String("\(vo.valueName) minval= \(minVal) maxval= \(maxVal)"))
        #endif

        //double vscale = d(self.bounds.size.height - (2.0f*BORDER)) / (maxVal - minVal);
        vScale = d(myTOGD.rect.size.height) / (maxVal - minVal)

        yZero -= CGFloat(minVal)
        yZero *= CGFloat(vScale)

        var mxdat: [NSNumber] = []
        var mydat: [NSNumber] = []

        //myTracker.sql = [NSString stringWithFormat:@"select date,val from voData where id=%d and val != '' order by date;",self.vo.vid];
        // 6.ii.2013 implement maxGraphDays
        let sql = String(format: "select date,val from voData where id=%ld and val != '' and date >= %d and date <= %d order by date;", Int(vo.vid), myTOGD.firstDate, myTOGD.lastDate)
        #if GRAPHDBG
        DBGLog(String("graph points sql: \(sql)"))
        #endif
        let idrslt = myTracker.toQry2AryID(sql: sql)
        //sql = nil;

        for (ni, nv) in idrslt {

            #if GRAPHDBG
            //DBGLog(String("i: \(ni)  f: \(nv)"))
            #endif
            var d = Double(ni) // date as int secs cast to float
            var v = Double(nv) // val as float
            //DBGLOG("\(vo.valueName!) \(d) \(v)")
            d -= Double(myTOGD.firstDate) // self.firstDate;
            d *= myTOGD.dateScale
            v -= minVal
            v *= vScale

            //d+= border; //BORDER;
            //v+= border; //BORDER;
            // fixed by doDrawGraph ? : why does this code run again after rotate to portrait?

            //DBGLog(@"num final: %f %f",d,v);

            mxdat.append(NSNumber(value: d))
            mydat.append(NSNumber(value: v))
        }


        xdat = mxdat
        ydat = mydat

        return self
    }

    func initAsNote(_ inVO: valueObj) -> vogd {
        //super.init()
        vo = inVO
        yZero = 0.0

        let myTracker = vo.parentTracker
        let myTOGD = myTracker.togd!

        vScale = d(myTOGD.rect.size.height) / d(1.1 + GRAPHSCALE) // (self.maxVal - self.minVal);
        //self.vScale = d(myTOGD.rect.size.height); // / d(1.05) ;  // (self.maxVal - self.minVal);

        var mxdat: [AnyHashable] = []
        var mydat: [AnyHashable] = []

        var i1: [Int] = []

        //NSMutableArray *s1 = [[NSMutableArray alloc] init];

        //myTracker.sql = [NSString stringWithFormat:@"select date,val from voData where id=%d and val not NULL and val != '' and date >= %d and date <= %d order by date;",self.vo.vid,myTOGD.firstDate,myTOGD.lastDate];
        //[myTracker toQry2AryIS:i1 s1:s1];
        //NSEnumerator *e = [s1 objectEnumerator];
        let sql = String(format: "select date,val from voData where id=%ld and val not NULL and val != '' and date >= %d and date <= %d order by date;", Int(vo.vid), myTOGD.firstDate, myTOGD.lastDate)
        i1 = myTracker.toQry2AryI(sql: sql)
        //sql = nil;

        for ni in i1 {
            //DBGLog(@"i: %@  ",ni);
            var d = Double(ni) // date as int secs cast to float

            d -= Double(myTOGD.firstDate)
            d *= myTOGD.dateScale
            //d+= border;

            mxdat.append(NSNumber(value: d))
            mydat.append(NSNumber(value: vScale)) //[e nextObject]];
        }


        //[s1 release];

        xdat = mxdat
        ydat = mydat

        return self

    }

    //- (vogd*) initAsBool:(valueObj*)vo;

    // not used - boolean treated as number
    /*
    - (id) initAsBool:(valueObj*)inVO {
        if ((self = [super init])) {

            self.vo = inVO;
            self.yZero = 0.0F;

            trackerObj *myTracker = self.vo.parentTracker;
            togd *myTOGD = myTracker.togd;

            NSMutableArray *mxdat = [[NSMutableArray alloc] init];
            //NSMutableArray *mydat = [[NSMutableArray alloc] init];

            NSMutableArray *i1 = [[NSMutableArray alloc] init];
           sql = [NSString stringWithFormat:@"select date from voData where id=%d and val !='' and date >= %d and date <= %d order by date;",self.vo.vid,myTOGD.firstDate,myTOGD.lastDate];
            [myTracker toQry2AryI:i1];
          //sql = nil;

            for (NSNumber *ni in i1) {

                //DBGLog(@"i: %@  ",ni);
                double d = [ni doubleValue];		// date as int secs cast to float

                d -= (double) myTOGD.firstDate;
                d *= myTOGD.dateScale;
                //d+= border;

                [mxdat addObject:[NSNumber numberWithDouble:d]];

            }
            [i1 release];


            self.xdat = [NSArray arrayWithArray:mxdat];
            //ydat = [NSArray arrayWithArray:mydat];

            [mxdat release];
            //[mydat release];
        }

        return self;

    }
    */

    func initAsTBoxLC(_ inVO: valueObj) -> vogd {

        //super.init()
        vo = inVO
        yZero = 0.0

        let myTracker = vo.parentTracker
        let myTOGD = myTracker.togd!

        minVal = 0.0
        maxVal = minVal

        //var i2: [Int] = []

        let sql = String(format: "select date,val, (LENGTH(val) - LENGTH(REPLACE(val, CHAR(10), '')) + 1) from voData where id=%ld and val not NULL and val != '' and date >= %d and date <= %d order by date;", Int(vo.vid), myTOGD.firstDate, myTOGD.lastDate)
        let rsltISI = myTracker.toQry2AryISI(sql: sql)
        //sql = nil;

        // TODO: nicer to cache tbox linecounts somehow
        /*
        for s in s1 {
            guard let s = s as? String else {
                continue
            }
            var v = d(rTracker_resource.countLines(s))
            if v > maxVal {
                maxVal = v
            }
            i2.append(NSNumber(value: v))
        }
         */

        for (_, _, i3) in rsltISI {
            let di3 = Double(i3)
            if di3 > maxVal {
                maxVal = di3
            }
        }
        if maxVal < d(YTICKS) {
            maxVal = d(YTICKS)
        }

        vScale = d(myTOGD.rect.size.height) / (maxVal - minVal)

        var mxdat: [NSNumber] = []
        var mydat: [NSNumber] = []

        //let e = (i2 as NSArray).objectEnumerator()

        for (i1, _, i3) in rsltISI {

            //DBGLog(@"i: %@  ",ni);
            var d = Double(i1) // date as int secs cast to float
            var v = Double(i3)

            d -= Double(myTOGD.firstDate)
            d *= myTOGD.dateScale

            v -= minVal
            v *= vScale

            mxdat.append(NSNumber(value: d))
            mydat.append(NSNumber(value: v))
        }



        xdat = mxdat
        ydat = mydat

        return self

    }

    func myGraphColor() -> UIColor {
        if 0 > vo.vcolor {
            return .white // VOT_CHOICE, VOT_INFO
        }

        let cs = rTracker_resource.colorSet()
        if cs.count <= vo.vcolor {
            // paranoid due to crashlytics report error in gtYAxV:drawYAxis but expect due to vcolor=-1
            DBGErr(String("myGraphColor: vcolor out of range: \(vo.vcolor) cs count= \(cs.count) vtype= \(vo.vtype)"))
            vo.vcolor = 0
        }

        return cs[vo.vcolor]

    }
}
