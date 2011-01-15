//
//  GrowLViewAppDelegate.m
//  GrowLView
//
//  Created by Faye Pearson on 14/01/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GrowLViewAppDelegate.h"
#import "LVMenuItem.h"
#import "NSMutableData+endian.h"

@implementation GrowLViewAppDelegate

@synthesize window;
@synthesize textView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSString *PngPath;
	PngPath = [[NSBundle mainBundle] pathForResource:@"mail" ofType:@"png"];
	mailPng = [[[NSData alloc] initWithContentsOfFile:PngPath] autorelease];
	liveView = [[LiveView alloc] init];
	[liveView registerWithCallback:self];
	[liveView addMenuItem:[LVMenuItem itemWithTitle:@"Mail" unread:1 image:mailPng isAlert:TRUE delegate:self]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[liveView stop];
	[liveView release];
	[mailPng release];
}

- (void)newLiveViewConnection {
	[textView insertText:[NSString stringWithFormat:@"New connection from version %@!\n",[liveView softwareVersion]]];
}

- (void)handleLiveViewAlertAction:(int)alertActionParam atItem:(int)menuItemParam;
{
	switch (alertActionParam) {
		case kAlertFirst:
			[textView insertText:[NSString stringWithFormat:@"First from item %d\n",menuItemParam]];
			break;
		case kAlertPrev:
			[textView insertText:[NSString stringWithFormat:@"Prev from item %d\n",menuItemParam]];
			break;
		case kAlertNext:
			[textView insertText:[NSString stringWithFormat:@"Next from item %d\n",menuItemParam]];
			break;
		case kAlertLast:
			[textView insertText:[NSString stringWithFormat:@"Last from item %d\n",menuItemParam]];
			break;
		case kAlertCurrent:
			[textView insertText:[NSString stringWithFormat:@"Current from item %d\n",menuItemParam]];
			break;
		default:
			[textView insertText:[NSString stringWithFormat:@"Unknown from item %d\n",menuItemParam]];
			break;
	}
}

- (void)handleLiveViewNavigationAction:(int)navActionParam ofType:(int)navTypeParam
								inMenu:(int)menuIdParam atItem:(int)menuItemParam {
	switch (navActionParam) {
		case kActionPress:
			[textView insertText: @"Pressed "];
			break;
		case kActionDoublePress:
			[textView insertText: @"Double-pressed "];
			break;
		case kActionLongPress:
			[textView insertText: @"Held "];
			break;
		default:
			break;
	}
	switch (navTypeParam) {
		case kNavUp:
			[textView insertText:[NSString stringWithFormat:@"Up on menu %d at item %d\n",menuIdParam,menuItemParam]];
			break;
		case kNavDown:
			[textView insertText:[NSString stringWithFormat:@"Down on menu %d at item %d\n",menuIdParam,menuItemParam]];
			break;
		case kNavLeft:
			[textView insertText:[NSString stringWithFormat:@"Left on menu %d at item %d\n",menuIdParam,menuItemParam]];
			break;
		case kNavRight:
			[textView insertText:[NSString stringWithFormat:@"Right on menu %d at item %d\n",menuIdParam,menuItemParam]];
			break;
		case kNavSelect:
			[textView insertText:[NSString stringWithFormat:@"Select on menu %d at item %d\n",menuIdParam,menuItemParam]];
			break;
		case kNavMenuSelect:
			[textView insertText:[NSString stringWithFormat:@"MenuSelect on menu %d at item %d\n",menuIdParam,menuItemParam]];
			break;
		default:
			[textView insertText:[NSString stringWithFormat:@"Unknown on menu %d at item %d\n",menuIdParam,menuItemParam]];
			break;
	}
}

- (void)handleLiveViewDeviceStatus:(int)status {
	switch (status) {
		case kDeviceStatusOff:
			[textView insertText:@"Screen powered off\n"];
			break;
		case kDeviceStatusOn:
			[textView insertText:@"Screen powered on\n"];
			break;
		case kDeviceStatusMenu:
			[textView insertText:@"Screen in menu mode\n"];
			break;
		default:
			[textView insertText:@"Device state unknown\n"];
			break;
	}
}


@end
