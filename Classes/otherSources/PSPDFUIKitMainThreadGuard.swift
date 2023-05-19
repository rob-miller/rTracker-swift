//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
// Taken from the commercial iOS PDF framework http://pspdfkit.com.
// Copyright (c) 2014 Peter Steinberger, PSPDFKit GmbH. All rights reserved.
// Licensed under MIT (http://opensource.org/licenses/MIT)
//
// You should only use this in debug builds. It doesn't use private API, but I wouldn't ship it.

import ObjectiveC
import UIKit

#if !RELEASE

typealias PSPDFLogError = DBGErr

//#define PSPDFAssert(expression, ...) do { if(!(expression)) {
//NSLog(@"%@", [NSString stringWithFormat: @"Assertion failure: %s in %s on line %s:%d. %@", #expression, __PRETTY_FUNCTION__, __FILE__, __LINE__, [NSString stringWithFormat:@"" __VA_ARGS__]]);
//abort(); }} while(0)

// Compile-time selector checks.
#if DEBUG
func PROPERTY(_ propName: Any) -> String {
    NSStringFromSelector(Selector("propName"))
}
#else
//#define PROPERTY(propName) @#propName
#endif

// http://www.mikeash.com/pyblog/friday-qa-2010-01-29-method-replacement-for-fun-and-profit.html

func PSPDFReplaceMethodWithBlock(_ c: AnyClass, _ origSEL: Selector, _ newSEL: Selector, _ block: Any?) -> Bool {
    PSPDFAssert(c != nil && origSEL != nil && newSEL != nil && block != nil)
    if c.instancesRespond(to: newSEL) {
        return true // Selector already implemented, skip silently.
    }

    let origMethod = class_getInstanceMethod(c, origSEL)

    // Add the new method.
    var impl: IMP? = nil
    if let block {
        impl = imp_implementationWithBlock(block)
    }
    if let origMethod, let impl {
        if !class_addMethod(c, newSEL, impl, method_getTypeEncoding(origMethod)) {
            PSPDFLogError("Failed to add method: %@ on %@", NSStringFromSelector(newSEL), c)
            return false
        } else {
            let newMethod = class_getInstanceMethod(c, newSEL)

            // If original doesn't implement the method we want to swizzle, create it.
            if let newMethod {
                if class_addMethod(c, origSEL, method_getImplementation(newMethod), method_getTypeEncoding(origMethod)) {
                    class_replaceMethod(c, newSEL, method_getImplementation(origMethod), method_getTypeEncoding(newMethod))
                } else {
                    method_exchangeImplementations(origMethod, newMethod)
                }
            }
        }
    }
    return true
}

func PSPDFPrefixedSelector(_ selector: Selector) -> Selector {
    return NSSelectorFromString("pspdf_\(NSStringFromSelector(selector))")
}

func PSPDFAssertIfNotMainThread() {
    PSPDFAssert(Thread.isMainThread, "\nERROR: All calls to UIKit need to happen on the main thread. You have a bug in your code. Use dispatch_async(dispatch_get_main_queue(), ^{ ... }); if you're unsure what thread you're in.\n\nBreak on PSPDFAssertIfNotMainThread to find out where.\n\nStacktrace: %@", Thread.callStackSymbols)
}

private func PSPDFUIKitMainThreadGuard() {
    autoreleasepool {
        for selStr in [
            PROPERTY(setNeedsLayout),
            PROPERTY(setNeedsDisplay),
            PROPERTY(setNeedsDisplayInRect:)
        ] {
            let selector = NSSelectorFromString(selStr)
            let newSelector = NSSelectorFromString("pspdf_\(selStr)")
            if selStr.hasSuffix(":") {
                PSPDFReplaceMethodWithBlock(UIView.self, selector, newSelector, { _self, r in
                    // Check for window, since *some* UIKit methods are indeed thread safe.
                    // https://developer.apple.com/library/ios/#releasenotes/General/WhatsNewIniPhoneOS/Articles/iPhoneOS4.html
                    /*
                                         Drawing to a graphics context in UIKit is now thread-safe. Specifically:

                                         The routines used to access and manipulate the graphics context can now correctly handle contexts residing on different threads.

                                         String and image drawing is now thread-safe.

                                         Using color and font objects in multiple threads is now safe to do.
                                         */
                    if _self?.window != nil {
                        PSPDFAssertIfNotMainThread()
                    }
                    (objc_msgSend)(_self, newSelector, r)
                })
            } else {
                PSPDFReplaceMethodWithBlock(UIView.self, selector, newSelector, { _self in
                    if _self?.window != nil {
                        if !Thread.isMainThread {
                            //#pragma clang diagnostic push
                            //#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                            let queue = dispatch_get_current_queue()
                            //#pragma clang diagnostic pop
                            // iOS 8 layouts the MFMailComposeController in a background thread on an UIKit queue.
                            // https://github.com/PSPDFKit/PSPDFKit/issues/1423
                            if queue == nil || !strstr(dispatch_queue_get_label(queue), "UIKit") {
                                PSPDFAssertIfNotMainThread()
                            }
                        }
                    }
                    (objc_msgSend)(_self, newSelector)
                })
            }
        }
    }
}
#endif