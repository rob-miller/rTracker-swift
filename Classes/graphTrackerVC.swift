//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// graphTrackerVC.swift
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
//  graphTracker.h
//  rTracker
//
//
//  need a view controller for presentModalViewController
//  but work is done in view
//
//  Created by Robert Miller on 28/09/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

///************
/// graphTRackerVC.m
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
//  graphTracker.m
//  rTracker
//
//  Created by Robert Miller on 28/09/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

//#import <libkern/OSAtomic.h>

import UIKit

// Note: DatePickerResult and DatePickerAction are defined in datePickerVC.swift

class graphTrackerVC: UIViewController, UIScrollViewDelegate {
    /*{
    	trackerObj *tracker;
        valueObj *currVO;
        UIFont *myFont;

        UIScrollView *scrollView;
        graphTrackerV *gtv;
        gtTitleV *titleView;
        gtVONameV *voNameView;
        gtXAxV *xAV;
        gtYAxV *yAV;

        DatePickerResult *dpr;

        useTrackerController *parentUTC;

        int32_t shakeLock;

    }
    */
    var tracker: trackerObj?
    var currVO: valueObj?
    var myFont: UIFont?
    var scrollView: UIScrollView?
    var gtv: graphTrackerV?
    var titleView: gtTitleV?
    var voNameView: gtVONameV?
    var xAV: gtXAxV?
    var yAV: gtYAxV?
    var dpr: DatePickerResult?
    var parentUTC: useTrackerController?

    
    func buildView() {


        let insets = rTracker_resource.getSafeAreaInsets()
        DBGLog("safe insets= Top: \(insets.top), Left: \(insets.left), Bottom: \(insets.bottom), Right: \(insets.right)")
        
        view.backgroundColor = .black

        var gtvRect: CGRect = CGRect.zero

        // get our own frame

        let srect = view.bounds

        DBGLog(String("gtvc srect: \(srect.origin.x) \(srect.origin.y) \(srect.size.width) \(srect.size.height)"))

        // add views for title, axes and labels

        myFont = UIFont(name: String(FONTNAME), size: CGFloat(FONTSIZE))
        let labelHeight = (myFont?.lineHeight ?? 0.0) + 2.0

        // view for title -- trackerName across top
        var rect: CGRect = CGRect.zero
        rect.origin.y = 0.0
        rect.size.height = labelHeight
        rect.origin.x = insets.left  // avoid dynamic island
        rect.size.width = srect.size.width - insets.left

        let ttv = gtTitleV(frame: rect)
        titleView = ttv
        titleView?.tracker = tracker
        titleView?.myFont = myFont
        //self.titleView?.backgroundColor = UIColor.green;  // debug

        if let titleView {
            view.addSubview(titleView)
        }
        // titleView done
        
        // graph rect y starts at the height of the titleView (measure from the top)
        gtvRect.origin.y = rect.size.height

        
        // view for y axis labels

        rect.origin.x = insets.left  // 0.0
        rect.size.width = getMaxDataLabelWidth() + (2 * SPACE) + TICKLEN + ceil(myFont?.lineHeight ?? 10.0) + SPACE
        rect.origin.y = titleView?.frame.size.height ?? 0.0
        rect.size.height = srect.size.height - labelHeight - insets.bottom   // ((2*labelHeight) + (3*SPACE) + TICKLEN);

        DBGLog(String("gtvc yax rect: \(rect.origin.x) \(rect.origin.y) \(rect.size.width) \(rect.size.height)"))

        yAV = gtYAxV(frame: rect)
        yAV?.myFont = myFont
        
        yAV?.scaleOriginY = 0.0
        yAV?.parentGTVC = self

        // done with y-axis labels
        
        // graph rect x starts at edge of y-axis labels, which is already shifted in by insets.left
        gtvRect.origin.x = rect.size.width + insets.left
        // graph rect width is total width minus the origin minus insets.right
        gtvRect.size.width = srect.size.width - gtvRect.origin.x - insets.right

    
        // view for x axis labels
        rect.origin.y = srect.size.height  - insets.bottom - ((2 * labelHeight) + (3 * SPACE) + TICKLEN)
        rect.size.height = srect.size.height - rect.origin.y  //BORDER - rect.size.width;
        rect.origin.x = gtvRect.origin.x
        rect.size.width = gtvRect.size.width

        DBGLog(String("gtvc xax rect: \(rect.origin.x) \(rect.origin.y) \(rect.size.width) \(rect.size.height)"))

        yAV?.scaleHeightY = rect.origin.y - (titleView?.frame.size.height ?? 0.0) // set bottom of y scale area

        xAV = gtXAxV(frame: rect)
        xAV?.myFont = myFont

        xAV?.scaleOriginX = 0.0
        xAV?.scaleWidthX = rect.size.width // x scale area is full length of subview

        gtvRect.size.height = rect.origin.y - gtvRect.origin.y

        // add scrollview for main graph
        scrollView = UIScrollView(frame: gtvRect)
        scrollView?.backgroundColor = .black
        //[self.scrollView setBackgroundColor:[UIColor greenColor]];
        scrollView?.delegate = self
        scrollView?.bouncesZoom = true

        if let scrollView {
            view.addSubview(scrollView)
        }

        DBGLog("did create scrollview")

        scrollView?.minimumZoomScale = 1.0
        scrollView?.maximumZoomScale = 5.0
        scrollView?.contentSize = CGSize(width: gtvRect.size.width, height: gtvRect.size.height)
        //self.scrollView.delegate=self;

        gtvRect.origin.x = 0.0
        gtvRect.origin.y = 0.0

        // load all togd, vogd data into NSArrays etc.

        tracker?.setTOGD(gtvRect)  // now we know the full gtvRect
        nextVO() // initialize self.currVO
        
        yAV?.vogd = currVO?.vogd as? vogd
        yAV?.graphSV = scrollView

        if let yAV {
            view.addSubview(yAV)
        }

        xAV?.mytogd = tracker?.togd as? Togd
        xAV?.graphSV = scrollView
        if let xAV {
            view.addSubview(xAV)
        }

        // add main graph view
        gtv = graphTrackerV(frame: gtvRect)
        gtv?.tracker = tracker
        gtv?.gtvCurrVO = currVO
        gtv?.parentGTVC = self
        if dpr?.action == .goto {
            let targSecs = Int(dpr!.date!.timeIntervalSince1970) - tracker!.togd!.firstDate
            gtv?.xMark = Double(targSecs) * (tracker!.togd!.dateScale)
            xAV?.markDate = dpr!.date
        }


        if let gtv {
            scrollView?.addSubview(gtv)
        }
    }

    // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad()
        buildView()
    }

    override func viewWillAppear(_ animated: Bool) {
        //DBGLog(@".");
        super.viewWillAppear(animated)

        if dpr?.action == .goto {
            let targSecs = Int(dpr!.date!.timeIntervalSince1970) - tracker!.togd!.firstDate
            gtv?.xMark = Double(targSecs) * (tracker!.togd!.dateScale)
        }

        if let _ = (tracker?.optDict)?["dirtyFns"] {
            fireRecalculateFns()
        }
        fireRegenSearchMatches()

    }

    override func viewWillDisappear(_ animated: Bool) {
        resignFirstResponder()
        //self.view.backgroundColor = [UIColor whiteColor];
        //[self.view.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
        //[self.view removeFromSuperview];
        super.viewWillDisappear(animated)
    }
    
    private var hasBuiltView = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Check if we need to rebuild the view (e.g., after rotation)
        let currentBounds = view.bounds
        if !hasBuiltView || currentBounds != previousBounds {
            // Remove existing subviews first
            for subview in view.subviews {
                subview.removeFromSuperview()
            }
            
            // Reset any view references
            titleView = nil
            yAV = nil
            xAV = nil
            gtv = nil
            scrollView = nil
            
            // Rebuild the view
            buildView()
            
            hasBuiltView = true
            previousBounds = currentBounds
        }
    }

    // Add this property to track when the bounds change
    private var previousBounds: CGRect = .zero

    // MARK: -
    // MARK: handle shake event

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func viewDidAppear(_ animated: Bool) {
        navigationController?.setToolbarHidden(true, animated: false)

        super.viewDidAppear(animated)

        becomeFirstResponder()
    }

    @objc func doRecalculateFns() {
        // and re-create graphs 
        autoreleasepool {
            tracker?.goRecalculate = true
            tracker?.recalculateFns()

            if tracker?.goRecalculate ?? false {
                tracker!.setTOGD(gtv?.frame ?? CGRect.zero)  // recreate all graph data
                tracker?.goRecalculate = false
            }

            //[rTracker_resource finishActivityIndicator:self.scrollView navItem:nil disable:NO];
            rTracker_resource.finishProgressBar(scrollView, navItem: nil, disable: false)
            DispatchQueue.main.async(execute: { [self] in
                gtv?.setNeedsDisplay()
                yAV?.setNeedsDisplay()
            })
            //self.shakeLock = 0; // release lock
        }

    }

    func fireRecalculateFns() {
        if tracker?.recalcFnLock.get() != false {
            return // already running
        }
        rTracker_resource.startProgressBar(scrollView, navItem: nil, disable: false, yloc: 20.0)
        Thread.detachNewThreadSelector(#selector(doRecalculateFns), toTarget: self, with: nil)
    }

    func fireRegenSearchMatches() {
        if nil != parentUTC?.searchSet {
            var xPoints: [NSNumber] = []
            if let aSearchSet = parentUTC?.searchSet {
                for d in aSearchSet {
                    if d >= tracker!.togd!.firstDate {
                        xPoints.append(NSNumber(value: Float(Double((d - tracker!.togd!.firstDate)) * tracker!.togd!.dateScale)))
                    }
                }
            }
            if 0 < xPoints.count {
                gtv?.searchXpoints = xPoints
                return // success
            }
        }
        // fall through to no match default result
        gtv?.searchXpoints = nil
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
        //if event?.type == UIEvent.EventSubtype.motionShake {
            // It has shake d
            /*
                    if (0 != OSAtomicTestAndSet(0, &(_shakeLock))) {
                        // wasn't 0 before, so we didn't get lock, so leave because shake handling already in process
                        return;
                    }
                     */
            if tracker?.goRecalculate ?? false {
                // recalculate is already running
                return
            }
            // we are first one here

            //[rTracker_resource startActivityIndicator:self.scrollView navItem:nil disable:NO];

            fireRecalculateFns()
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return gtv
    }

    /*
    - (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
        CGRect newFrame =  view.frame;
        DBGLog(@"sv did end zooming scale=%f",scale);
        DBGLog(@"view frame -- x:%f y:%f w:%f h:%f",newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height);
        newFrame =  view.bounds;
        DBGLog(@"view bounds -- x:%f y:%f w:%f h:%f",newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height);
        DBGLog(@"sv cOffset x:%f y:%f cSize w:%f h:%f cInset t:%f l:%f b:%f r:%f",scrollView.contentOffset.x,scrollView.contentOffset.y,
               scrollView.contentSize.width,scrollView.contentSize.height,scrollView.contentInset.top,scrollView.contentInset.left,
               scrollView.contentInset.bottom,scrollView.contentInset.right);

    }
    */


    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //DBGLog(@"sv did scroll");
        //DBGLog(@"sv cOffset x:%f y:%f cSize w:%f h:%f cInset t:%f l:%f b:%f r:%f",self.scrollView.contentOffset.x,self.scrollView.contentOffset.y,
        //       self.scrollView.contentSize.width,self.scrollView.contentSize.height,self.scrollView.contentInset.top,self.scrollView.contentInset.left,
        //       self.scrollView.contentInset.bottom,self.scrollView.contentInset.right);

        xAV?.setNeedsDisplay()
        yAV?.setNeedsDisplay()

    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        //DBGLog(@"sv did zoom");
        //DBGLog(@"sv cOffset x:%f y:%f cSize w:%f h:%f cInset t:%f l:%f b:%f r:%f",self.scrollView.contentOffset.x,self.scrollView.contentOffset.y,
        //       self.scrollView.contentSize.width,self.scrollView.contentSize.height,self.scrollView.contentInset.top,self.scrollView.contentInset.left,
        //       self.scrollView.contentInset.bottom,self.scrollView.contentInset.right);

        xAV?.setNeedsDisplay()
        yAV?.setNeedsDisplay()

    }

    /*
    - (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
        DBGLog(@"sv did end scrolling animation");
        DBGLog(@"sv cOffset x:%f y:%f cSize w:%f h:%f cInset t:%f l:%f b:%f r:%f",scrollView.contentOffset.x,scrollView.contentOffset.y,
               scrollView.contentSize.width,scrollView.contentSize.height,scrollView.contentInset.top,scrollView.contentInset.left,
               scrollView.contentInset.bottom,scrollView.contentInset.right);

    }

    - (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
        DBGLog(@"sv did end decelerating");
        DBGLog(@"sv cOffset x:%f y:%f cSize w:%f h:%f cInset t:%f l:%f b:%f r:%f",scrollView.contentOffset.x,scrollView.contentOffset.y,
               scrollView.contentSize.width,scrollView.contentSize.height,scrollView.contentInset.top,scrollView.contentInset.left,
               scrollView.contentInset.bottom,scrollView.contentInset.right);

    }
     */

    // MARK: -
    // MARK: close up code

    override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()

        // Release any cached data, images, etc that aren't in use.
    }

    /*
    - (void)viewDidUnload {
    	self.tracker = nil;
        [super viewDidUnload];
        // Release any retained subviews of the main view.
        // e.g. self.myOutlet = nil;
    }
    */

    deinit {
        DBGLog("deallocating graphTrackerVC")

    }

    // MARK: -
    // MARK: view rotation methods

    /* pre ios6
    - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
        if (0 != self.shakeLock)
            return NO;
        // Return YES for supported orientations
    	switch (interfaceOrientation) {
    		case UIInterfaceOrientationPortrait:
    			DBGLog(@"gt should rotate to interface orientation portrait?");
                if ( SYSTEM_VERSION_LESS_THAN(@"5.0") ) { //if not 5
                    [self.parentUTC returnFromGraph];
                }

    			break;
    		case UIInterfaceOrientationPortraitUpsideDown:
    			DBGLog(@"gt should rotate to interface orientation portrait upside down?");
    			break;
    		case UIInterfaceOrientationLandscapeLeft:
    			DBGLog(@"gt should rotate to interface orientation landscape left?");
                //[self doGT];
    			break;
    		case UIInterfaceOrientationLandscapeRight:
    			DBGLog(@"gt should rotate to interface orientation landscape right?");
                //[self doGT];
    			break;
    		default:
    			DBGWarn(@"gt rotation query but can't tell to where?");
    			break;			
    	}

        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown );
    }
    */

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if isViewLoaded && view.window != nil {

            coordinator.animate(alongsideTransition: { [self] context in
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                let orientation = windowScene!.interfaceOrientation
                /*
                //UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
                let firstWindow = UIApplication.shared.windows.first
                let windowScene = firstWindow?.windowScene
                let orientation = windowScene?.interfaceOrientation
                 */
                // do whatever  -- willRotateTo

                switch orientation {
                case .portrait:
                    DBGLog("gt will rotate to interface orientation portrait")
                    tracker?.goRecalculate = false // stop!!!!
                case .portraitUpsideDown:
                    DBGLog("gt will rotate to interface orientation portrait upside down")
                    tracker?.goRecalculate = false // stop!!!!
                case .landscapeLeft:
                    DBGLog("gt will rotate to interface orientation landscape left")
                    gtv?.doDrawGraph = true
                case .landscapeRight:
                    DBGLog("gt will rotate to interface orientation landscape right")
                    gtv?.doDrawGraph = true
                default:
                    DBGWarn("gt will rotate but can't tell to where")
                }

            }) { [self] context in
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                let orientation = windowScene!.interfaceOrientation
                /*
                //UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
                let firstWindow = UIApplication.shared.windows.first
                let windowScene = firstWindow?.windowScene
                let orientation = windowScene?.interfaceOrientation
                 */
                // do whatever -- didRotateTo
                switch orientation {
                case .portrait:
                    DBGLog("gt did rotate to interface orientation portrait")
                    parentUTC?.returnFromGraph()
                case .portraitUpsideDown:
                    DBGLog("gt did rotate to interface orientation portrait upside down")
                    //[self.parentUTC returnFromGraph];
                case .landscapeLeft:
                    DBGLog("gt did rotate to interface orientation landscape left")
                case .landscapeRight:
                    DBGLog("gt did rotate to interface orientation landscape right")
                default:
                    DBGWarn("gt did rotate but can't tell to where")
                }
            }
        }
        super.viewWillTransition(to: size, with: coordinator)
    }

    //@property (atomic)     int32_t shakeLock;

    /*
    - (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
    {
    	switch (fromInterfaceOrientation) {
    		case UIInterfaceOrientationPortrait:
    			DBGLog(@"gt did rotate from interface orientation portrait");
    			break;
    		case UIInterfaceOrientationPortraitUpsideDown:
    			DBGLog(@"gt did rotate from interface orientation portrait upside down");
    			break;
    		case UIInterfaceOrientationLandscapeLeft:
    			DBGLog(@"gt did rotate from interface orientation landscape left");
    			break;
    		case UIInterfaceOrientationLandscapeRight:
    			DBGLog(@"gt did rotate from interface orientation landscape right");
    			break;
    		default:
    			DBGLog(@"gt did rotate but can't tell from where");
    			break;			
    	}

        if ( SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0") ) {// if 5.0
            if ((self.interfaceOrientation ==  UIInterfaceOrientationPortrait) || (self.interfaceOrientation ==  UIInterfaceOrientationPortraitUpsideDown)) {
                [self.parentUTC returnFromGraph];
                //[[self presentingViewController] dismissViewControllerAnimated:YES
                //                                                    completion:nil];
            }
        }

    }
    */
    /*
    - (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
    {
        //rtm dbg self.gtv.doDrawGraph=FALSE;
        self.gtv.doDrawGraph=TRUE;

    	switch (toInterfaceOrientation) {
    		case UIInterfaceOrientationPortrait:
    			DBGLog(@"gt will rotate to interface orientation portrait duration: %f sec",duration);
                self.tracker.goRecalculate=NO; // stop!!!!
                break;
    		case UIInterfaceOrientationPortraitUpsideDown:
    			DBGLog(@"gt will rotate to interface orientation portrait upside down duration: %f sec", duration);
                self.tracker.goRecalculate=NO; // stop!!!!
                break;
    		case UIInterfaceOrientationLandscapeLeft:
    			DBGLog(@"gt will rotate to interface orientation landscape left duration: %f sec", duration);
                self.gtv.doDrawGraph=TRUE;
    			break;
    		case UIInterfaceOrientationLandscapeRight:
    			DBGLog(@"gt will rotate to interface orientation landscape right duration: %f sec", duration);
                self.gtv.doDrawGraph=TRUE;
    			break;
    		default:
    			DBGErr(@"gt will rotate but can't tell to where duration: %f sec", duration);
    			break;			
    	}
    }
    */

    /*
    - (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
    {
    	switch (interfaceOrientation) {
    		case UIInterfaceOrientationPortrait:
    			DBGLog(@"gt will animate rotation to interface orientation portrait duration: %f sec",duration);
    			break;
    		case UIInterfaceOrientationPortraitUpsideDown:
    			DBGLog(@"gt will animate rotation to interface orientation portrait upside down duration: %f sec", duration);
    			break;
    		case UIInterfaceOrientationLandscapeLeft:
    			DBGLog(@"gt will animate rotation to interface orientation landscape left duration: %f sec", duration);
    			break;
    		case UIInterfaceOrientationLandscapeRight:
    			DBGLog(@"gt will animate rotation to interface orientation landscape right duration: %f sec", duration);
    			break;
    		default:
    			DBGErr(@"gt will animate rotation but can't tell to where duration: %f sec", duration);
    			break;			
    	}
    }
    */



    // MARK: -
    // MARK: touch support
    /*
    - (NSString*) touchReport:(NSSet*)touches {

    #if DEBUGLOG
    	UITouch *touch = [touches anyObject];
    	CGPoint touchPoint = [touch locationInView:self.view];
    	return [NSString stringWithFormat:@"touch at %f, %f.  taps= %d  numTouches= %d",
                touchPoint.x, touchPoint.y, [touch tapCount], [touches count]];
    #endif
        return @"";

    }

    - (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
        DBGLog(@"gvc touches began: %@", [self touchReport:touches]);
    }

    - (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
        DBGLog(@"gvc touches cancelled: %@", [self touchReport:touches]);
    }

    - (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
        DBGLog(@"gvc touches ended: %@", [self touchReport:touches]);
    }

    - (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
        DBGLog(@"gvc touches moved: %@", [self touchReport:touches]);
    }

    */

    /*
    - (valueObj*) currVO {
        if (nil == currVO) {
            [self nextVO];
        }
        return currVO;
    }
    */

    // MARK: -
    // MARK: handle taps in subviews

    func yavTap() {
        //if (0 != self.shakeLock) return;
        if tracker!.recalcFnLock.get() {
            return
        }
        //DBGLog(@"yav tapped!");
        nextVO()
        yAV?.vogd = currVO?.vogd as? vogd
        yAV?.setNeedsDisplay()
        gtv?.gtvCurrVO = currVO // double line width
        gtv?.setNeedsDisplay()
    }

    func gtvTap(_ touches: Set<AnyHashable>?) {
        //if (0 != self.shakeLock) return;
        if tracker!.recalcFnLock.get() {
            return
        }
        //DBGLog(@"gtv tapped!");
        //int xMarkSecs;
        let touch = touches?.first as? UITouch

        if (1 == touch?.tapCount) && (1 == (touches?.count ?? 0)) {
            let touchPoint = touch?.location(in: gtv) // sv=> full zoomed content size ; gtv => gtv frame but zoom/scroll mapped
            DBGLog("gtv tap at \(touchPoint!.x), \(touchPoint!.y).  taps= \(touch!.tapCount)  numTouches= \(touches!.count)");

            let nearDate = Int(Double(tracker!.togd!.firstDate) + (touchPoint!.x * (tracker!.togd!.dateScaleInv)))
            let newDate = tracker?.dateNearest(nearDate) ?? 0
            dpr?.date = Date(timeIntervalSince1970: TimeInterval(newDate))
            dpr?.action = .goto
            //self.gtv.xMark = touchPoint.x;
            gtv?.xMark = Double(newDate - tracker!.togd!.firstDate) * tracker!.togd!.dateScale
            xAV?.markDate = dpr?.date
        } else if (2 == touch?.tapCount) && (1 == (touches?.count ?? 0)) {
            DBGLog("gtvTap: cancel")
            gtv?.xMark = NOXMARK
            dpr?.action = .goto
            dpr?.date = nil
            xAV?.markDate = nil
        } else {
            DBGLog("gtvTap: null event")
        }

        gtv?.setNeedsDisplay()
        xAV?.setNeedsDisplay()
    }

    // MARK: -
    // MARK: private methods

    func testStrWidth(_ testStr: String?, max: CGFloat) -> CGFloat {
        var tsize: CGSize? = nil
        if let myFont {
            tsize = testStr?.size(withAttributes: [
                NSAttributedString.Key.font: myFont
            ])
        }
        return (max < (tsize?.width ?? 0.0) ? tsize?.width : max) ?? 0.0
    }

    func testDblWidth(_ testVal: Double, max: CGFloat) -> CGFloat {
        return testStrWidth("\(testVal)", max: max)
    }

    func getMaxDataLabelWidth() -> CGFloat {
        // TODO: can we cache this in optDict?

        var maxw: CGFloat = 0.0
        var nmax, nmin, bval: NSNumber?
        for vo in tracker?.valObjTableH ?? [] {
            if "1" == vo.optDict["graph"] {
                switch vo.vtype {
                case VOT_NUMBER, VOT_FUNC:
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
                    if "0" == vo.optDict["autoscale"] {
                        maxw = testDblWidth(Double(vo.optDict["gmin"]!)!, max: maxw)
                        maxw = testDblWidth(Double(vo.optDict["gmax"]!)!, max: maxw)
                    } else {
                        var sql = String(format: "select min(val collate BINARY) from voData where id=%ld;", vo.vid) // CMPSTRDBL
                        maxw = testDblWidth(tracker?.toQry2Double(sql:sql) ?? 0.0, max: maxw)
                        sql = String(format: "select max(val collate BINARY) from voData where id=%ld;", vo.vid) // CMPSTRDBL
                        maxw = testDblWidth(tracker?.toQry2Double(sql:sql) ?? 0.0, max: maxw)
                    }
                case VOT_SLIDER:
                    nmin = NSNumber(value:Double(vo.optDict["smin"]!)!)
                    nmax = NSNumber(value:Double(vo.optDict["smax"]!)!)
                    maxw = testDblWidth(nmin != nil ? nmin!.doubleValue : d(SLIDRMINDFLT), max: maxw)
                    maxw = testDblWidth(nmax != nil ? nmax!.doubleValue : d(SLIDRMAXDFLT), max: maxw)
                case VOT_BOOLEAN:
                    //bval = NSNumber(pointer:vo.optDict["boolval"])
                    bval = NSNumber(value: Double(vo.optDict["boolval"]!)!)
                    //DBGLog("bval= \(bval)")
                    maxw = testDblWidth(bval != nil ? bval!.doubleValue : d(BOOLVALDFLT), max: maxw)
                case VOT_CHOICE:
                    for i in 0..<CHOICES {
                        if let s = vo.optDict["c\(i)"], !s.isEmpty {
                            maxw = testStrWidth(s, max: maxw)
                        }
                    }
                default:
                    maxw = testDblWidth(d(99), max: maxw)
                }
            }
        }

        //sql = nil;

        return maxw
    }

    func testSetVO(_ vo: valueObj?) -> Bool {
        if "1" == (vo?.optDict)?["graph"] && vo?.vGraphType != VOG_NONE {
            currVO = vo
            return true
        }
        return false
    }

    func nextVO() {
        if nil == currVO {
            // no currVO set, work through list and set first one that has graph enabled
            for vo in tracker?.valObjTableH ?? [] {
                if testSetVO(vo) {
                    return
                }
            }
        } else {
            // currVO is set, find it in list and then circle around trying to find next that has graph enabled
            var currNdx: Int? = nil
            if let currVO {
                currNdx = tracker?.valObjTableH.firstIndex(of: currVO) ?? NSNotFound
            }
            var ndx = (currNdx ?? 0) + 1
            var maxc = tracker?.valObjTableH.count
            while true {
                while ndx < maxc! {
                    if testSetVO(tracker?.valObjTableH[ndx] as? valueObj) {
                        return
                    }
                    ndx += 1
                }
                if ndx == currNdx {
                    return
                }
                ndx = 0
                maxc = currNdx ?? 0
            }
        }

    }
}

extension graphTrackerVC {
}
