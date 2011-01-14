//
//  LVMenuItem.h
//  GrowLView
//
//  Created by Faye Pearson on 14/01/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LVMenuItem : NSObject {
	BOOL isAlertItem;
	int unreadCount;
	NSString *title;
	NSData *image;
	NSObject *callback;
}

- (NSString *)title;
- (void)setTitle:(NSString *)titleParam;
- (int)unreadCount;
- (void)setUnread:(int)num;
- (BOOL)isAlertItem;
- (void)setAlert:(BOOL)is;
- (NSData *)image;
- (void)setImage:(NSData *)img;
+ (LVMenuItem *)itemWithTitle:(NSString *)titleParam
			   unread:(int)unreadParam
				image:(NSData *)imageParam
			  isAlert:(BOOL)alertParam
			 delegate:(NSObject *)callbackParam;
@end
