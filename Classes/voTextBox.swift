//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// voTextBox.swift
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
//  voTextBox.swift
//  rTracker
//
//  Created by Robert Miller on 01/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import AddressBook
import Contacts
import Foundation
import UIKit

class CustomAccessoryView: UIView {

    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var segControl: UISegmentedControl!
    @IBOutlet weak var searchSeg: UISegmentedControl!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var orAndSeg: UISegmentedControl!
    var votb: voTextBox!
    
    class func instanceFromNib(_ invotb: voTextBox) -> CustomAccessoryView {
        let cav =  UINib(nibName: "voTBacc2", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CustomAccessoryView
        cav.votb = invotb
        return cav
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Initialize your view
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Initialize your view

    }
    @IBAction func addButtonPressed(_ sender: Any) {
        //print("addButton pressed")
        votb.addPickerData()
    }
    
    @IBAction func clearButtonPressed(_ sender: UIButton) {
        votb.clear()
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        //print("seg changed")
        votb.segmentChanged(sender.selectedSegmentIndex)
    }
    
    @IBAction func searchSegChanged(_ sender: UISegmentedControl) {
        if 0 == searchSeg.selectedSegmentIndex {
            orAndSeg.isHidden = true
            clearButton.isHidden = false
        } else {
            orAndSeg.isHidden = false
            clearButton.isHidden = true
        }
    }
    
    func initAccView() {
        addButton.isHidden = true
        let fsize: CGFloat = 20.0
        segControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: fsize)
        ], for: .normal)
        
        segControl.accessibilityIdentifier = "tbox-seg-control"
        segControl.subviews[0].accessibilityLabel = "Contacts"
        segControl.subviews[0].accessibilityHint = "select to choose from Contacts"
        segControl.subviews[0].accessibilityIdentifier = "tbox-seg-contacts"
        
        segControl.subviews[1].accessibilityLabel = "History"
        segControl.subviews[1].accessibilityHint = "select to choose lines from previous entries"
        segControl.subviews[1].accessibilityIdentifier = "tbox-seg-history"
        
        segControl.subviews[2].accessibilityLabel = "Keyboard"
        segControl.subviews[2].accessibilityHint = "select to use keyboard"
        segControl.subviews[2].accessibilityIdentifier = "tbox-seg-keyboard"
        
        searchSeg.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: fsize)
        ], for: .normal)
        
        searchSeg.accessibilityIdentifier = "tbox-seg-search"
        searchSeg.subviews[1].accessibilityLabel = "Use"
        searchSeg.subviews[1].accessibilityHint = "select to use text for this entry"
        searchSeg.subviews[1].accessibilityIdentifier = "tbox-mode-use"

        searchSeg.subviews[0].accessibilityLabel = "Search"
        searchSeg.subviews[0].accessibilityHint = "select to use text for searching previous entries"
        searchSeg.subviews[0].accessibilityIdentifier = "tbox-mode-srch"
        
        orAndSeg.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: fsize)
        ], for: .normal)
        
        orAndSeg.accessibilityIdentifier = "tbox-seg-search-mode"
        orAndSeg.subviews[0].accessibilityLabel = "And"
        orAndSeg.subviews[0].accessibilityHint = "search for entries with all lines"
        orAndSeg.subviews[0].accessibilityIdentifier = "tbox-srch-and"

        orAndSeg.subviews[1].accessibilityLabel = "Or"
        orAndSeg.subviews[1].accessibilityHint = "search for entries with any of lines"
        orAndSeg.subviews[1].accessibilityIdentifier = "tbox-srch-or"

    }
    
}  // end of accessoryView


class voTextBox: voState, UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate {
    /*{

        UIButton *tbButton;
    	UITextView *textView;
    	UIView *accessoryView;
    	UIButton *addButton;
    	UISegmentedControl *segControl;
    	UIPickerView *pv;

    	NSArray *alphaArray;
    	NSArray *namesArray;
    	NSArray *historyArray;
    	NSArray *historyNdx;
        NSArray *namesNdx;

    	//NSMutableDictionary *peopleDict;
    	//NSMutableDictionary *historyDict;

    	BOOL showNdx;

    	voDataEdit *devc;
    	CGRect saveFrame;

        useTrackerController *parentUTC;

    }*/

    private var _tbButton: UIButton?
    var tbButton: UIButton? {
        if nil == _tbButton {
            _tbButton = UIButton(type: .roundedRect)
            _tbButton?.frame = vosFrame //CGRectZero;
            _tbButton?.contentVerticalAlignment = .center
            _tbButton?.contentHorizontalAlignment = .center
            _tbButton?.addTarget(self, action: #selector(tbBtnAction(_:)), for: .touchDown)
            _tbButton?.tag = kViewTag // tag this view for later so we can remove it from recycled table cells
            _tbButton?.titleLabel?.font = PrefBodyFont
            // rtm 06 feb 2012
            _tbButton?.accessibilityHint = "tap to edit textbox"
            _tbButton?.accessibilityIdentifier = "\(tvn())_tbButton"
        }
        return _tbButton
    }
    var textView: UITextView?
    var cav: CustomAccessoryView!
    
    private var _pv: UIPickerView?
    var pv: UIPickerView? {
        if nil == _pv {
            _pv = UIPickerView(frame: .zero)
            _pv?.autoresizingMask = .flexibleWidth
            // no effect after ios7 _pv.showsSelectionIndicator = YES;	// note this is default to NO
            // this view controller is the data source and delegate
            _pv?.delegate = self
            _pv?.dataSource = self
            if showNdx {
                _pv?.selectRow(1, inComponent: 0, animated: false)
            }
        }

        return _pv
    }

    private var _alphaArray: [AnyHashable]?
    let alphaArray = [
                "#",
                "A",
                "B",
                "C",
                "D",
                "E",
                "F",
                "G",
                "H",
                "I",
                "J",
                "K",
                "L",
                "M",
                "N",
                "O",
                "P",
                "Q",
                "R",
                "S",
                "T",
                "U",
                "V",
                "W",
                "X",
                "Y",
                "Z"
            ]

    private var _namesArray: [String]?
    var namesArray: [String] = []

    private var _historyArray: [String]?
    var historyArray: [String] {
        var sql: String
        if nil == _historyArray {
            //NSMutableArray *his1 = [[NSMutableArray alloc] init];
            var s0: Set<String> = []
            sql = String(format: "select val from voData where id = %ld and val != '';", Int(vo.vid))
            let his0 = MyTracker.toQry2AryS(sql: sql)
            for s in his0 {
                let s1 = s.replacingOccurrences(of: "\r", with: "\n")
                /*
                #if DEBUGLOG
                            NSArray *sepset= [s1 componentsSeparatedByString:@"\n"];
                            DBGLog(@"s= %@",s1);
                            DBGLog(@"c= %lu separated= .%@.",(unsigned long)sepset.count,sepset);
                #endif
                             */
                if s1 != "" {
                    s0.formUnion(Set(s1.components(separatedBy: "\n")))
                }
            }
            s0 = s0.filter { NSPredicate(format: "SELF != ''").evaluate(with: $0) }  // lose blank/null entries
            _historyArray = Array(s0).sorted{
                $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            }

            //DBGLog(@"historyArray count= %lu  content= .%@.",(unsigned long)_historyArray.count,_historyArray);
            //historyArray = [[NSArray alloc] initWithArray:his1];

            //DBGLog(@"his array looks like:");
            //for (NSString *s in historyArray) {
            //	DBGLog(s);
            //}
        }
        return _historyArray!
    }

    private var _historyNdx: [Int]?
    var historyNdx: [Int] {
        if nil == _historyNdx {
            var ndx = 0
            let notSet = -1
            var tmpHistoryNdx = getNSMA(notSet)

            for str in historyArray {
                let firstc = str.first!  // unichar(str[str.index(str.startIndex, offsetBy: 0)])
                enterNSMA(&tmpHistoryNdx, c: firstc, dflt: notSet, ndx: ndx)
                ndx += 1
            }

            // now set any unfilled indices to 'start of next section' or last item
            fillNSMA(&tmpHistoryNdx, dflt: notSet)

            _historyNdx = tmpHistoryNdx
        }
        return _historyNdx!
    }

    private var _namesNdx: [Int]?
    var namesNdx: [Int] {
        // with addressbook deprecation, just take first letter and ignore user sort order
        if nil == _namesNdx {
            var ndx = 0
            //ABPropertyID abSortOrderProp = [self getABSortTok];
            let notSet =  -1
            var tmpNamesNdx = getNSMA(notSet)

            for name in namesArray {
                let firstc = name.first!  // unichar(name[name.index(name.startIndex, offsetBy: 0)])

                enterNSMA(&tmpNamesNdx, c: firstc, dflt: notSet, ndx: ndx)

                ndx += 1
            }

            // now set any unfilled indices to 'start of next section' or last item
            fillNSMA(&tmpNamesNdx, dflt: notSet)

            _namesNdx = tmpNamesNdx
        }

        return _namesNdx!
    }
    var parentUTC: useTrackerController?
    //@property (nonatomic,retain) NSMutableDictionary *peopleDictionary;
    //@property (nonatomic,retain) NSMutableDictionary *historyDictionary;
    var devc: voDataEdit?
    //@property (nonatomic) CGRect saveFrame;
    var showNdx = false
    var accessAddressBook = false
    /*
    @IBOutlet weak var setSearchSeg: UISegmentedControl!
    @IBOutlet weak var orAndSeg: UISegmentedControl!
     */

 
    /*
    init() {
        //DBGLog(@"voTextBox default init");
        super.init(vo: nil)
    }
     */

    override func getValCap() -> Int {
        // NSMutableString size for value
        return 96
    }

    override init(vo valo: valueObj) {
        //DBGLog(@"voTextBox init for %@",valo.valueName);
        super.init(vo: valo)
    }

    deinit {
        //DBGLog(@"dealloc voTextBox");

        //DBGLog(@"tbBtn= %0x  rcount= %d",tbButton,[tbButton retainCount]);
        // convenience constructor, do not own (enven tho retained???)
        //foo accessoryView = nil
        cav = nil
        devc = nil

        //self.alphaArray = nil;

    }

    @objc func tbBtnAction(_ sender: Any?) {
        // textbox pressed in tracker, bring up editor view
        //DBGLog(@"tbBtn Action.");
        //voDataEdit *vde = [[voDataEdit alloc] initWithNibName:@"voDataEdit" bundle:nil ];
        let vde = voDataEdit()
        vde.vo = vo
        devc = vde // assign
        parentUTC = MyTracker.vc?.navigationController?.visibleViewController as? useTrackerController

        MyTracker.vc?.navigationController?.pushViewController(vde, animated: true)
        //[MyTracker.vc.navigationController push :vde animated:YES];


    }

    override func dataEditVDidLoad(_ vc: UIViewController) {
        //self.devc = vc;
        //CGRect visFrame = vc.view.frame;
        textView = UITextView(frame: voDataEdit.getInitTVF(vc), textContainer: nil) // ]vc.view.frame];

        textView?.textColor = .label
        textView?.font = PrefBodyFont // [UIFont fontWithName:@"Arial" size:18];
        textView?.delegate = self
        textView?.backgroundColor = .secondarySystemBackground

        textView?.text = vo.value
        textView?.returnKeyType = .default
        textView?.keyboardType = .default // use the default type input method (entire keyboard)
        textView?.isScrollEnabled = true
        textView?.isUserInteractionEnabled = true
        //self.textView.layoutManager.allowsNonContiguousLayout = NO;

        //self.textView.contentOffset = CGPointZero;
        //[self.textView setTextContainerInset:UIEdgeInsetsMake(7, 7, 0, 0)];
        // this will cause automatic vertical resize when the table is resized
        textView?.autoresizingMask = .flexibleHeight

        // note: for UITextView, if you don't like autocompletion while typing use:
        // myTextView.autocorrectionType = UITextAutocorrectionTypeNo;

        textView?.accessibilityIdentifier = "tbox-textview"
        if let textView {
            if textView.inputAccessoryView == nil {
                cav = CustomAccessoryView.instanceFromNib(self)
                textView.inputAccessoryView = cav // myAccessoryView  /* accessoryView
                cav.initAccView()
            }
            vc.view.addSubview(textView)
        }

        keyboardIsShown = false

        if vo.value == "" {
            textView?.becomeFirstResponder()
        }
        
    }

    override func dataEditVWAppear(_ vc: UIViewController?) {
        //self.devc = vc;
        //DBGLog(@"de view will appear");

        let aParentTracker = vo.parentTracker
        NotificationCenter.default.addObserver(
            aParentTracker,
            selector: #selector(trackerObj.trackerUpdated(_:)),
            name: NSNotification.Name(rtValueUpdatedNotification),
            object: nil)
        

        if let parentUTC {
            NotificationCenter.default.addObserver(
                parentUTC,
                selector: #selector(useTrackerController.updateUTC(_:)),
                name: NSNotification.Name(rtTrackerUpdatedNotification),
                object: vo.parentTracker)
        }

        /*
            //DBGLog(@"add kybd will show notifcation");
        	keyboardIsShown = NO;

            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(keyboardWillShow:)
                                                         name:UIKeyboardWillShowNotification
                                                       //object:self.textView];    //.devc.view.window];
                                                       object:self.devc.view.window];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(keyboardWillHide:)
                                                         name:UIKeyboardWillHideNotification
                                                       //object:self.textView];    //.devc.view.window];	
                                                       object:self.devc.view.window];	
             */
    }

    override func dataEditVWDisappear(_ vc: UIViewController?) {
        //DBGLog(@"de view will disappear");

        // unregister this tracker for value updated notifications
        let aParentTracker = vo.parentTracker
        NotificationCenter.default.removeObserver(
            aParentTracker,
            name: NSNotification.Name(rtValueUpdatedNotification),
            object: nil)
        

        //unregister for tracker updated notices

        if let parentUTC {
            NotificationCenter.default.removeObserver(
                parentUTC,
                name: NSNotification.Name(rtTrackerUpdatedNotification),
                object: nil)
        }

        /*
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:UIKeyboardWillShowNotification
                                                          object:nil];
        												  //--object:self.textView];    // nil]; //self.devc.view.window];
                                                          //object:self.devc.view.window];
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:UIKeyboardWillHideNotification
                                                          object:nil];
                                                          //object:self.textView];    // nil];   // self.devc.view.window];
                                                          //object:self.devc.view.window];
        */
    }

 
    // MARK: -
    // MARK: UITextViewDelegate

    /*
    - (void)keyboardWillShow:(NSNotification *)aNotification;
    - (void)keyboardWillHide:(NSNotification *)aNotification;
    */
    func clear() {
        textView?.text = ""
    }

    func addPickerData() {
        var row = 0
        var str: String = ""

        if showNdx {
            row = pv?.selectedRow(inComponent: 1) ?? 0
        } else {
            row = pv?.selectedRow(inComponent: 0) ?? 0
        }
        if SEGPEOPLE == cav.segControl.selectedSegmentIndex {
            if 0 == namesArray.count {
                rTracker_resource.alert("No Contacts", msg: "Add some names to your Address Book, then find them here", vc: nil)
            } else if accessAddressBook {
                str = "\(namesArray[row])\n"
            }
        } else {
            if 0 == historyArray.count {
                rTracker_resource.alert("No history", msg: "Use the keyboard to create some entries, then find them in the history", vc: nil)
            } else {
                let aHistoryArray = historyArray[row]
                str = "\(aHistoryArray)\n"
            }
        }

        //DBGLog(@"add picker data %@",str);
        textView?.text = (textView?.text ?? "") + str
    }
     

    //@IBAction func segmentChanged(_ sender: UISegmentedControl) {
    func segmentChanged(_ ndx:Int) {
        //let ndx = sender.selectedSegmentIndex
        //DBGLog(@"segment changed: %ld",(long)ndx);


        
        if textView?.inputView != nil {
            // if was showing pickerview
            pv?.removeFromSuperview() // remove leftover constraints if showed before
            _pv = nil // force regenerate
        }

        if SEGKEYBOARD == ndx {
            cav.addButton.isHidden = true
            textView?.inputView = nil
        } else {
            if SEGPEOPLE == ndx {
                checkContactsAccess()
                if !accessAddressBook {
                    cav.segControl.selectedSegmentIndex = SEGKEYBOARD
                    segmentChanged(SEGKEYBOARD)
                    return
                }
                if !ABloaded {
                    accessABcondition.lock()
                    while !ABloaded {
                        accessABcondition.wait()
                    }
                    accessABcondition.unlock()
                }
                if 0 == namesArray.count {
                    rTracker_resource.alert("No Contacts", msg: "Add some names to your Address Book, then find them here", vc: nil)
                    cav.segControl.selectedSegmentIndex = SEGKEYBOARD
                    segmentChanged(SEGKEYBOARD)
                    return
                }
            } else {  // SEGHISTORY
                if 0 == historyArray.count {
                    rTracker_resource.alert("No history", msg: "Use the keyboard to create some entries, save, and then find them in the history", vc: nil)
                    cav.segControl.selectedSegmentIndex = SEGKEYBOARD
                    segmentChanged(SEGKEYBOARD)
                    return
                }
            }
            cav.addButton.isHidden = false
            if ((SEGPEOPLE == ndx) && (vo.optDict["tbni"] == "1") && accessAddressBook)
                || ((SEGHISTORY == ndx) && (vo.optDict["tbhi"] == "1")) {
                showNdx = true
            } else {
                showNdx = false
            }

            textView?.inputView = pv
        }

        textView?.resignFirstResponder()
        textView?.becomeFirstResponder()
        
        if let selectedRange = textView?.selectedRange {
            textView?.scrollRangeToVisible(selectedRange)
        }
    }
     
    
    @objc func saveAction(_ sender: Any?) {
        // finish typing text/dismiss the keyboard by removing it as the first responder
        //
        textView?.resignFirstResponder()
        devc?.navigationItem.rightBarButtonItem = nil // this will remove the "save" button
        textView?.text = textView?.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if "" != textView?.text {
            textView?.text = (textView?.text ?? "") + "\n"
        }

        DBGLog(String("tb save: vo.val= .\(vo.value)  tv.txt= \(textView!.text)"))

        if 0 == cav.searchSeg.selectedSegmentIndex {
            if vo.value != textView?.text {
                vo.value = textView?.text ?? ""

                vo.display = nil // so will redraw this cell only
                NotificationCenter.default.post(name: NSNotification.Name(rtValueUpdatedNotification), object: self)
            }
        } else {
            let txtStrings = textView!.text.components(separatedBy: "\n")
            let searchStrings = Set<AnyHashable>(txtStrings)

            var sql = String(format: "select distinct date from voData where id=%ld and (", Int(vo.vid)) // privacy ok because else can't see textbox
            let oasi = cav.orAndSeg.selectedSegmentIndex
            let orAnd = Bool(oasi != 0)
            var cont = false
            for ss in searchStrings {
                guard let ss = ss as? String else {
                    continue
                }
                var st = ss.trimmingCharacters(in: .whitespaces)
                st = rTracker_resource.toSqlStr(st) ?? ""
                if 0 < st.count {
                    if cont {
                        sql = sql + (orAnd ? " and " : " or ")
                    }
                    sql = sql + String(format: "val like '%%%@%%'", st)
                    cont = true
                }
            }

            if !sql.hasSuffix("(") {
                // if ends with '(' then did not add any search terms
                sql = sql + ")"
                DBGLog(String("sql= \(sql)"))
                let searchDates = parentUTC!.tracker!.toQry2AryI(sql: sql)
                DBGLog(String("returns \(UInt(searchDates.count)) entries"))
                if 0 < searchDates.count {
                    parentUTC?.searchSet = searchDates
                } else {
                    parentUTC?.searchSet = nil
                }
            } else {
                parentUTC?.searchSet = nil
            }
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        // provide my own Save button to dismiss the keyboard
        let saveItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(voDataEdit.saveAction(_:)))
        
        saveItem.accessibilityLabel = "Save"
        saveItem.accessibilityHint = "tap to save text to entry"
        saveItem.accessibilityIdentifier = "tbox-save"
        
        devc?.navigationItem.rightBarButtonItem = saveItem
    }

    /*
    func textViewShouldBeginEditing(_ aTextView: UITextView) -> Bool {
        if false { //textView?.inputAccessoryView == nil {
            cav = CustomAccessoryView.instanceFromNib(self)
            textView?.inputAccessoryView = cav 
            cav.initAccView()
        }
        return true
    }
    */
    func textViewShouldEndEditing(_ aTextView: UITextView) -> Bool {
        aTextView.resignFirstResponder()
        return true
    }

    // MARK: -
    // MARK: get contacts

    // largely copied from https://gist.github.com/willthink/024f1394474e70904728
    // and https://stackoverflow.com/questions/36859991/cncontact-display-name-objective-c-swift
    // NSCondition additions from gpt4
    let accessABcondition = NSCondition()
    var accessABknown: Bool = false
    var ABloaded: Bool = false
    func checkContactsAccess() {
        let entityType: CNEntityType = .contacts
        let stat = CNContactStore.authorizationStatus(for: entityType)

        if .authorized == stat {
            accessAddressBook = true
        } else if .notDetermined == stat {
            let contactStore = CNContactStore()
            contactStore.requestAccess(for: entityType) { [self] granted, error in
                accessABcondition.lock()
                if granted {
                    accessAddressBook = true
                } else {
                    accessAddressBook = false
                }
                accessABknown = true
                accessABcondition.signal()
                accessABcondition.unlock()
            }
            
            accessABcondition.lock()
            while !accessABknown {
                accessABcondition.wait()
            }
            accessABcondition.unlock()
        } else {
            accessAddressBook = false
            rTracker_resource.alert("Need Contacts access", msg: "Please go to System Settings -> Privacy -> Contacts and enable access for rTracker to use this feature.",
                                    vc:nil)
        }
        
        if accessAddressBook {
            DispatchQueue.global().async { [weak self] in
                self?.accessABcondition.lock()
                self?.getNames()
                self?.ABloaded = true
                self?.accessABcondition.signal()
                self?.accessABcondition.unlock()
            }
        }
        
    }

    func getNames() {
        if namesArray != [] {
            return
        }
        checkContactsAccess()
        if !accessAddressBook {
            return
        }

        // https://stackoverflow.com/questions/36859991/cncontact-display-name-objective-c-swift
        var contacts: [CNContact] = []
        let contactStore = CNContactStore()

        let fnameKey = CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
        let keysToFetch = [CNContactIdentifierKey, fnameKey] as! [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)

        // Enumerate the contacts
        do {
            try contactStore.enumerateContacts(with: request, usingBlock: { (contact, stop) in
                contacts.append(contact)
            })
        } catch let error {
            DBGLog("error fetching contacts = \(error)")
        }
        
        // Create a contact formatter
        let formatter = CNContactFormatter()

        // Loop through the contacts and add their names to the array
        for contact in contacts {
            let name = formatter.string(from: contact)
            namesArray.append(name!)
        }

    }

    override func voDisplay(_ bounds: CGRect) -> UIView {
        vosFrame = bounds

        if vo.value == "" {
            tbButton?.setTitle("<add text>", for: .normal)
        } else {
            tbButton?.setTitle(vo.value, for: .normal)
        }
        // does not help ! [[self.tbButton superview] setNeedsDisplay];
        // does not help ! [self.tbButton setNeedsDisplay];
        tbButton?.setNeedsLayout()
        //DBGLog(@"tbox voDisplay: %@",[self.tbButton currentTitle]);
        return tbButton!

    }

    override func voGraphSet() -> [String] {
        if vo.optDict["tbnl"] == "1" {
            // linecount is a num for graph
            return voState.voGraphSetNum()
        } else {
            return super.voGraphSet()
        }
    }

    // MARK: -
    // MARK: options page

    override func setOptDictDflts() {

        if nil == vo.optDict["tbnl"] {
            vo.optDict["tbnl"] = TBNLDFLT ? "1" : "0"
        }
        if nil == vo.optDict["tbni"] {
            vo.optDict["tbni"] = TBNIDFLT ? "1" : "0"
        }
        if nil == vo.optDict["tbhi"] {
            vo.optDict["tbhi"] = TBHIDFLT ? "1" : "0"
        }

        return super.setOptDictDflts()
    }

    override func cleanOptDictDflts(_ key: String) -> Bool {

        let val = vo.optDict[key]
        if nil == val {
            return true
        }

        if ((key == "tbnl") && (val == (TBNLDFLT ? "1" : "0"))) || ((key == "tbni") && (val == (TBNIDFLT ? "1" : "0"))) || ((key == "tbhi") && (val == (TBHIDFLT ? "1" : "0"))) {
            vo.optDict.removeValue(forKey: key)
            return true
        }

        return super.cleanOptDictDflts(key)
    }

    override func voDrawOptions(_ ctvovc: configTVObjVC) {
        var frame = CGRect(x: MARGIN, y: ctvovc.lasty , width: 0.0, height: 0.0)
        var labframe = ctvovc.configLabel("Text box options:", frame: frame, key: "tboLab", addsv: true)
        frame.origin.y += labframe.size.height + MARGIN
        labframe = ctvovc.configLabel("Use number of lines for graph value:", frame: frame, key: "tbnlLab", addsv: true) // can't do cleanly for function value (can't get linecount in sql and still use for other vtypes)
        frame = CGRect(x:labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)
        frame = ctvovc.configCheckButton(
            frame,
            key: "tbnlBtn",
            state: (vo.optDict["tbnl"] == "1") /* default:0 */,
            addsv: true)

        // need index picker for contacts else unusable

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        labframe = ctvovc.configLabel("Names index:", frame: frame, key: "tbniLab", addsv: true)
        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)
        frame = ctvovc.configCheckButton(
            frame,
            key: "tbniBtn",
            state: !(vo.optDict["tbni"] == "0"),
            addsv: true)

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        labframe = ctvovc.configLabel("History index:", frame: frame, key: "tbhiLab", addsv: true)
        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)
        frame = ctvovc.configCheckButton(
            frame,
            key: "tbhiBtn",
            state: (vo.optDict["tbhi"] == "1") /* default:0 */,
            addsv: true)

        //*/

        //	frame.origin.x = MARGIN;
        //	frame.origin.y += MARGIN + frame.size.height;
        //
        //	labframe = [self configLabel:@"Other options:" frame:frame key:@"soLab" addsv:YES];

        ctvovc.lasty = frame.origin.y + labframe.size.height + MARGIN

        super.voDrawOptions(ctvovc)
    }

    func getNSMA(_ dflt: Int) -> [Int]{
        let c = alphaArray.count

        var tmpNSMA: [Int] = [] // (repeating: 0, count: alphaArray?.count ?? 0)
        for i in 0..<c {
            tmpNSMA.insert(dflt, at: i)
        }
        return tmpNSMA
    }

    func enterNSMA(_ NSMA: inout [Int], c: Character, dflt: Int, ndx: Int) {
        let aaNdx = alphaArray.firstIndex(of: "\(c.uppercased())") ?? NSNotFound
        if NSNotFound == aaNdx {
            if dflt == NSMA[0] {
                // is a non-alpha, update index if it is first found
                NSMA[0] = ndx
            }
        } else if dflt == NSMA[aaNdx] {
            // only update if this is first for this letter
            NSMA[aaNdx] = ndx
        }
    }

    func fillNSMA(_ NSMA: inout [Int], dflt: Int) {

        var ndx = alphaArray.count - 1
        var newVal: NSNumber? = nil
        if let lastObject = NSMA.last {
            newVal = NSNumber(value: NSMA.firstIndex(of: lastObject) ?? NSNotFound)
        }
        while ndx >= 0 {
            if dflt == NSMA[ndx] {
                if let newVal {
                    NSMA[ndx] = newVal.intValue
                }
            } else {
                newVal = NSNumber(value:NSMA[ndx])
            }
            ndx -= 1
        }
    }

    // MARK: -
    // MARK: picker view
    //- (void) updatePickerArrays:(NSInteger)row {
    //	NSMutableDictionary *foo = self.peopleDictionary;
    //}

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if showNdx {
            return 2
        }
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if showNdx && 0 == component {
            return alphaArray.count
         } else {
             if SEGPEOPLE == cav.segControl.selectedSegmentIndex {
                if accessAddressBook {
                    return namesArray.count
                } else {
                    return 0
                }
            } else {
                return historyArray.count
            }
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if showNdx && 0 == component {
            return alphaArray[row]
        } else {
            if SEGPEOPLE == cav.segControl.selectedSegmentIndex {
                if accessAddressBook {
                    return namesArray[row]
                } else {
                    return ""
                }
            } else {
                return historyArray[row]
            }
         }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if showNdx {
            //NSArray *srcArr,*targArr;
            var otherComponent: Int
            var targRow: Int
            if component == 0 {
                //srcArr = self.alphaArray;
                otherComponent = 1
                if SEGPEOPLE == cav.segControl.selectedSegmentIndex {
                    targRow = namesNdx[row]
                } else {
                    targRow = historyNdx[row]
                }
                //DBGLog(@"showndx on : did sel row targ %d component %d",targRow,component);
            } else {
                otherComponent = 0
                if SEGPEOPLE == cav.segControl.selectedSegmentIndex {
                    if !accessAddressBook {
                        return
                    }
                    // deprecated ios 9 ABPropertyID abSortOrderProp = [self getABSortTok];
                    if 0 == namesArray.count {
                        return
                    }
                    let name = namesArray[row]
                    targRow = alphaArray.firstIndex(of: "\(name.uppercased().first!)") ?? 0   //   toupper(name![name!.index(name!.startIndex, offsetBy: 0)]))"))!
                    //if NSNotFound == targRow {
                    //    targRow = 0
                    //}
                } else {
                    if 0 == historyArray.count {
                        return // crashlytics crash on next line in 2.0.5 - past array bounds
                    }
                    targRow = alphaArray.firstIndex(of: "\(historyArray[row].uppercased().first!)") ?? 0//  "\(toupper(historyArray![row][(historyArray![row].index(historyArray![row].startIndex, offsetBy: 0))]))") ?? NSNotFound
                    //if NSNotFound == targRow {
                    //    targRow = 0
                    //}
                }
            }

            pickerView.selectRow(targRow, inComponent: otherComponent, animated: true)
        }
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {

        var componentWidth: CGFloat = 280.0
 
        if showNdx {
            if component == 0 {
                componentWidth = 40.0 // first column size is narrow for letters
            } else {
                componentWidth = 240.0 // second column is max size
            }
        }

        return componentWidth
    }

    // MARK: -
    // MARK: graph display

    /*
     - (void) transformVO:(NSMutableArray *)xdat ydat:(NSMutableArray *)ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate {
        // TODO: handle case of value=linecount
        [self transformVO_note:xdat ydat:ydat dscale:dscale height:height border:border firstDate:firstDate];

    }
    */

    override func newVOGD() -> vogd {
        if vo.optDict["tbnl"] == "1" {
            // linecount is a num for graph
            return vogd(vo).initAsTBoxLC(vo)
        } else {
            return vogd(vo).initAsNote(vo)
        }
    }

    override func mapValue2Csv() -> String? {
        // add from history or contacts adds trailing \n, trim it here
        return vo.value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

let SEGPEOPLE = 0
let SEGHISTORY = 1
let SEGKEYBOARD = 2
