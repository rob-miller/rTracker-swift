//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// voImage.swift
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

// Image valueObj desired but not implemented due to perceived complexities displaying on graph

//
//  voImage.swift
//  rTracker
//
//  Created by Robert Miller on 01/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import Foundation

//@interface voImage : voState <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

class voImage: voState, UINavigationControllerDelegate {
    var imageView: UIImageView?
    var takePhotoButton: UIButton?
    var selectFromCameraRollButton: UIButton?
    var pickFromLibraryButton: UIButton?
    var devc: voDataEdit?

    override func getValCap() -> Int {
        // NSMutableString size for value
        return 64
    }

    // MARK: -
    // MARK: table cell item display

    @objc func imgBtnAction(_ sender: Any?) {
        DBGLog("imgBtn Action.")
        let vde = voDataEdit(nibName: "voDataEdit", bundle: nil)
        vde.vo = vo
        devc = vde // assign
        MyTracker?.vc?.navigationController?.pushViewController(vde, animated: true)

    }

    override func voDisplay(_ bounds: CGRect) -> UIView? {
        let imageButton = UIButton(type: .custom)
        imageButton.frame = bounds //CGRectZero;
        imageButton.contentVerticalAlignment = .center
        imageButton.contentHorizontalAlignment = .right //Center;
        imageButton.addTarget(self, action: #selector(imgBtnAction(_:)), for: .touchDown)

        imageButton.setImage(UIImage(named: "blueButton.png"), for: .normal)

        //imageButton.tag = kViewTag;	// tag this view for later so we can remove it from recycled table cells

        return imageButton
    }

    // MARK: -
    // MARK: voSDataEdit support -- get image

    func getCameraPhoto(_ sender: Any?) {
        /*
        	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        	picker.delegate = self;
        	picker.allowsEditing = YES;
        	picker.sourceType = 
        		(sender == self.takePhotoButton) ? UIImagePickerControllerSourceTypeCamera :	UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        	//[self.devc presentModalViewController:picker animated:YES];
            [self.devc presentViewController:picker animated:YES completion:NULL];
             */
    }

    func getExistingPhoto(_ sender: Any?) {
        /*
        	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        		UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        		picker.delegate = self;
        		picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        		//[self.devc presentModalViewController:picker animated:YES];
                [self.devc presentViewController:picker animated:YES completion:NULL];
        	} else {
                [rTracker_resource alert:@"Error accessing photo library" msg:@"Device does not support a photo library" vc:nil];
        	}
             */
    }

    override func dataEditVDidLoad(_ vc: UIViewController?) {
        /*
        	self.imageView = [[UIImageView alloc] initWithFrame:vc.view.frame];
        	if (![self.vo.value isEqualToString:@""]) {
        		self.imageView.image = [UIImage imageWithContentsOfFile:self.vo.value];
        	}
        	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        		self.takePhotoButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        		self.takePhotoButton.frame = CGRectMake(100.0, 100.0, 120.0, 40.0); //CGRectZero;
        		self.takePhotoButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        		self.takePhotoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        		[self.takePhotoButton addTarget:self action:@selector(getCameraPhoto:) forControlEvents:UIControlEventTouchUpInside];		
        		[self.takePhotoButton setTitle:@"take photo" forState:UIControlStateNormal];
        		self.takePhotoButton.tag = kViewTag;	// tag this view for later so we can remove it from recycled table cells

        		[self.devc.view addSubview:self.takePhotoButton];
        		self.takePhotoButton = nil;

        		self.selectFromCameraRollButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        		self.selectFromCameraRollButton.frame = CGRectMake(100.0, 150.0, 120.0, 40.0); //CGRectZero;
        		self.selectFromCameraRollButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        		self.selectFromCameraRollButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        		[self.selectFromCameraRollButton addTarget:self action:@selector(getCameraPhoto:) forControlEvents:UIControlEventTouchUpInside];		
        		[self.selectFromCameraRollButton setTitle:@"pick from camera roll" forState:UIControlStateNormal];

        		[self.devc.view addSubview:self.selectFromCameraRollButton];
        		self.selectFromCameraRollButton = nil;

        	}

        	self.pickFromLibraryButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        	self.pickFromLibraryButton.frame = CGRectMake(100.0, 200.0, 120.0, 40.0); //CGRectZero;
        	self.pickFromLibraryButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        	self.pickFromLibraryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        	[self.pickFromLibraryButton addTarget:self action:@selector(getExistingPhoto:) forControlEvents:UIControlEventTouchUpInside];		
        	[self.pickFromLibraryButton setTitle:@"pick from library" forState:UIControlStateNormal];

        	[self.devc.view addSubview:self.pickFromLibraryButton];
        	self.pickFromLibraryButton = nil;
        	*/
    }

    override func dataEditVWAppear(_ vc: UIViewController?) {
    }

    override func dataEditVWDisappear(_ vc: UIViewController?) {
    }

    /*
    - (void) dataEditVDidUnload {
    	self.imageView = nil;
    	self.takePhotoButton = nil;
    	self.selectFromCameraRollButton = nil;
    	self.pickFromLibraryButton = nil;
    }
    */

    // MARK: -
    // MARK: imagePickerController delegate support


    //- (void) imagePickerController:(UIImagePickerController *)picker
    //		 didFinishPickingImage:(UIImage*)image
    //				   editingInfo:(NSDictionary*)editingInfo {

    /*
    - (void) imagePickerController:(UIImagePickerController *)picker
    		 didFinishPickingMediaWithInfo:(NSDictionary *)mediaInfo {
    	self.imageView.image = mediaInfo[UIImagePickerControllerOriginalImage];  // TODO: needs more work could be edited or video
    	//[picker dismissModalViewControllerAnimated:YES];
        [picker dismissViewControllerAnimated:YES completion:NULL];
    }

    - (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    	//[picker dismissModalViewControllerAnimated:YES];
        [picker dismissViewControllerAnimated:YES completion:NULL];
    }
    */


    // MARK: -
    // MARK: options page

    override func setOptDictDflts() {

        return super.setOptDictDflts()
    }

    override func cleanOptDictDflts(_ key: String?) -> Bool {

        let val = (vo?.optDict)?[key ?? ""] as? String
        if nil == val {
            return true
        }

        return super.cleanOptDictDflts(key)
    }

    override func voDrawOptions(_ ctvovc: configTVObjVC?) {

        let labframe = ctvovc?.configLabel(
            "need Image Location -- Options:",
            frame: CGRect(x: MARGIN, y: ctvovc?.lasty ?? 0.0, width: 0.0, height: 0.0),
            key: "ioLab",
            addsv: true)

        ctvovc?.lasty += (labframe?.size.height ?? 0.0) + MARGIN
        super.voDrawOptions(ctvovc)
    }

    // MARK: -
    // MARK: graph display

    /*
     - (void) transformVO:(NSMutableArray *)xdat ydat:(NSMutableArray *)ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate {

        [self transformVO_note:xdat ydat:ydat dscale:dscale height:height border:border firstDate:firstDate];

    }
    */

    override func newVOGD() -> Any? {
        // TODO: need to handle image differently from note
        return vogd?.initAsNote(vo)
    }
}