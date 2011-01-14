//
//  GrowLViewAppDelegate.h
//  GrowLView
//
//  Created by Faye Pearson on 14/01/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LiveView.h"
#import "LiveViewCallback.h"

@interface GrowLViewAppDelegate : NSObject <NSApplicationDelegate,LiveViewCallback> {
    NSWindow *window;
	NSTextView *textView;
	NSData *mailPng;
	LiveView *liveView;
}


@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextView *textView;

@end
