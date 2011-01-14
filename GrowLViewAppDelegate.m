//
//  GrowLViewAppDelegate.m
//  GrowLView
//
//  Created by Faye Pearson on 14/01/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GrowLViewAppDelegate.h"
#import "LVMenuItem.h"

@implementation GrowLViewAppDelegate

@synthesize window;
@synthesize textView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSString *PngPath;
	PngPath = [[NSBundle mainBundle] pathForResource:@"mail" ofType:@"png"];
	mailPng = [[NSData alloc] initWithContentsOfFile:PngPath];
	liveView = [[LiveView alloc] init];
	[liveView registerWithCallback:self];
	[liveView addMenuItem:[LVMenuItem itemWithTitle:@"Mail" unread:0 image:mailPng isAlert:FALSE delegate:self]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[liveView stop];
	[liveView release];
	[mailPng release];
}

- (void)newLiveViewConnection {
	[textView insertText:[NSString stringWithFormat:@"New connection!\n"]];
}

- (void)handleLiveViewNavigation:(int)navigation {
}

- (void)handleLiveViewDeviceStatus:(int)status {
}


@end
