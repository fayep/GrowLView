//
//  LVMenuItem.m
//  GrowLView
//
//  Created by Faye Pearson on 14/01/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LVMenuItem.h"

@implementation LVMenuItem
- (NSString *)title {
	return title;
}

- (void)setTitle:(NSString *)titleParam {
	[title release];
	[titleParam retain];
	title = titleParam;
}

- (int)unreadCount {
	return unreadCount;
}

- (void)setUnread:(int)num {
	unreadCount = num;
}

- (BOOL)isAlertItem {
	return isAlertItem;
}

- (void)setAlert:(BOOL)is {
	isAlertItem = is;
}

- (NSData *)image {
	return image;
}

- (void)setImage:(NSData *)img {
	[image release];
	[img retain];
	image = img;
}

- (void)setDelegate:(NSObject *)dgt {
	[callback release];
	[dgt retain];
	callback = dgt;
}

- (void)dealloc {
	[image release];
	[title release];
	[callback release];
	[super dealloc];
}

+ (LVMenuItem *)itemWithTitle:(NSString *)titleParam
			   unread:(int)unreadParam
				image:(NSData *)imageParam
			  isAlert:(BOOL)alertParam
			 delegate:(NSObject *)callbackParam {
	
	LVMenuItem *ret = [[[LVMenuItem alloc] init] autorelease];
	[ret setAlert:alertParam];
	[ret setUnread:unreadParam];
	[ret setTitle:titleParam];
	[ret setImage:imageParam];
	[ret setDelegate:callbackParam];
	return ret;
}

@end
