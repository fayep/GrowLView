//
//  LiveView.h
//  GrowLView
//
//  Created by Faye Pearson on 14/01/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import "LiveViewCallback.h"
#import "LVMenuItem.h"

@interface LiveView : NSObject {
	int width, height,
		statusBarWidth, statusBarHeight,
		viewWidth, viewHeight,
		announceWidth, announceHeight,
		textChunkSize, idleTimer;
	int menuItemId,navAction,navType,alertAction,maxBodySize;
	LiveViewStatus_t screenStatus;
	BOOL wasInAlert;
	
	NSString *softwareVersion;
	NSMutableArray *menuItems;
	NSObject<LiveViewCallback> *callback;
	BluetoothRFCOMMChannelID serverChannelID;
	BluetoothSDPServiceRecordHandle serverHandle;
	IOBluetoothUserNotification *incomingChannelNotification;
	IOBluetoothRFCOMMChannel *rfcommChannel;
	BluetoothRFCOMMMTU channelMTU;
	
}

- (NSString*)softwareVersion;
- (void)registerWithCallback:(NSObject<LiveViewCallback> *)lvc;
- (void)addMenuItem:(LVMenuItem *)item;
- (void)stop;
@end
