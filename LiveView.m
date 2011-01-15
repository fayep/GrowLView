//
//  LiveView.m
//  GrowLView
//
//  Created by Faye Pearson on 14/01/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LiveView.h"
#import	"NSMutableData+endian.h"

@interface LiveView (Private)

- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength;
- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel*)rfcommChannelParam;
- (void) newRFCOMMChannelOpened:(IOBluetoothUserNotification *)inNotification
                        channel:(IOBluetoothRFCOMMChannel *)newChannel;
- (void)rfcommChannelWriteComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel refcon:(void*)refcon status:(IOReturn)error;
- (void)sendMessage: (LiveViewMessage_t)msg withData:(NSData *)data;
- (void)sendData:(NSData *)data;
- (void)stop;

@end

#if 1
#define DebugLog(...) NSLog(__VA_ARGS__)
#else
#define DebugLog(...)
#endif

@implementation LiveView

/* addMenuItem
	LVMenuItem *item
 
	Add a menu item to the LiveView object.  This will need to trigger an update to the
	device if the device is already connected
 */

- (NSString*)softwareVersion {
	return softwareVersion;
}

- (void)addMenuItem:(LVMenuItem *)item {
	if (menuItems==nil) {
		menuItems = [[NSMutableArray alloc] init];
	}
	[item retain];
	[menuItems addObject:item];
}

- (void)sendMenuItemResponse:(int)number item:(LVMenuItem *)item {
	NSMutableData *output = [[[NSMutableData alloc] init] autorelease];
	[output serializeWithFormat:@">BHHHBBSSS", ![item isAlertItem], 0, [item unreadCount],
	 0, number+3, 0, @"", @"", [item title]];
	[output appendData:[item image]];
	DebugLog(@"Sending item %@",[item title]);
	[self sendMessage:kMessageGetMenuItem_Resp withData:output];
}	

- (void)handleLiveViewMessage:(LiveViewMessage_t)msg withData:(NSData *)data {
	NSMutableData *output = [[[NSMutableData alloc] init] autorelease];
	int number = 0;
	int c = 0;
	int navigation = 0;
	int menuId = 0;
	NSString *sa, *sb, *sc;
	LVMenuItem *i;
	[output appendint8:msg];
	[self sendMessage:kMessageAck withData:output];
	switch (msg) {
		case kMessageGetCaps_Resp:
			width=height=statusBarWidth=statusBarHeight=
			viewWidth=viewHeight=announceWidth=announceHeight=
			textChunkSize=idleTimer=0;
			[data deserializeWithFormat:@">BBBBBBBBBBs",
			 &width,&height,&statusBarWidth,&statusBarHeight,
			 &viewWidth,&viewHeight,&announceWidth,&announceHeight,
			 &textChunkSize, &idleTimer, &softwareVersion];
			[softwareVersion retain];
			if (idleTimer!=0) {
				DebugLog(@"DisplayCapabilities with non-zero idle timer %d", idleTimer);
			}
			DebugLog(@"Connection from LiveView with Version %@", softwareVersion);
			[callback newLiveViewConnection];
			[output setLength:0];
			[output appendint8:[menuItems count]];
			[self sendMessage:kMessageSetMenuSize withData: output];
			break;
			
		case kMessageGetMenuItem:
			[data deserializeWithFormat:@">B",&number];
			[output setLength:0];
			[self sendMenuItemResponse:number item:[menuItems objectAtIndex:number]];
			break;
			
		case kMessageGetMenuItems:
			[data deserializeWithFormat:@">B",&number];
			if (number) DebugLog(@"GetMenuItems with non-zero argument: %d",number);
			[output setLength:0];
			for (c=0;c<[menuItems count]; c++)
				[self sendMenuItemResponse:c item:[menuItems objectAtIndex:c]];
			break;
			
		case kMessageGetAlert:
			[data deserializeWithFormat:@">BBHsss",&menuItemId,&alertAction,&maxBodySize,&sa,&sb,&sc];
			if ([sa length] || [sb length] || [sc length]) {
				DebugLog(@"GetAlert with non-zero text: %@,%@,%@",sa,sb,sc);
			}
			i=[menuItems objectAtIndex:menuItemId];
			[output setLength:0];
			[output serializeWithFormat:@">BHHHBB", 0, 20, [i unreadCount], 15, 0, 0];
			[output serializeWithFormat:@">SSSBL",
			 @"Time", @"Header", @"01234567890123456789012345678901234567890123456789", 0,
			 [[i image] length]];
			[output appendData:[i image]];
			[self sendMessage:kMessageGetAlert_Resp withData:output];
			[callback handleLiveViewAlertAction:alertAction atItem:menuItemId];
			break;
			
		case kMessageSetStatusBar_Resp:
			[output setLength:0];
			[output appendint8:5];
			[output appendint8:12];
			[output appendint8:0];
			[self sendMessage:kMessageSetMenuSettings withData:output];
			break;
			
		case kMessageGetTime:
			[output setLength:0];
			NSDate *d=[[[NSDate alloc] init] autorelease];
			int now=[d timeIntervalSince1970];
			int tzoff=[[NSTimeZone localTimeZone] secondsFromGMTForDate:d];
			[output serializeWithFormat:@"LB",now+tzoff,0];
			[self sendMessage:kMessageGetTime_Resp withData:output];
			break;
			
		case kMessageDeviceStatus:
			[data deserializeWithFormat:@">B",&screenStatus];
			[output setLength:0];
			[output appendint8:kResultOK];
			[self sendMessage:kMessageDeviceStatus_Resp withData:output];
			[callback handleLiveViewDeviceStatus:screenStatus];
			break;
			
		case kMessageNavigation:
			number=navigation=menuItemId=menuId=0;
			[data deserializeWithFormat:@">HBBB", &number, &navigation, &menuItemId, &menuId];
			if (number!=3)
				DebugLog(@"Unexpected navigation message length: %d [%@]",number, data);
			else if (menuId != 10 && menuId != 20)
				DebugLog(@"Unexpected navigation menu ID: %d",menuId);
			else if (navigation !=32 && ((navigation<1)||(navigation>15)))
				DebugLog(@"Navigation type out of range: %d",navigation);
			else {
				wasInAlert = (menuId == 20);
				if (navigation!=32) {
					navAction = (navigation-1)%3;
					navType = (navigation-1)/3;
				} else {
					navAction = kActionPress;
					navType = kNavMenuSelect;
				}
				[callback handleLiveViewNavigationAction:navAction ofType:navType
												  inMenu:menuId atItem:menuItemId];
			}
			[output setLength:0];
			[output appendint8:kResultExit];
			[self sendMessage:kMessageNavigation_Resp withData:output];
			break;
		default:
			DebugLog(@"Message %d with data [%@]\n", msg, data);
			break;
	}
}

- (void)handleRawNotification:(NSData *)data {
	DebugLog(@"Unknown data [%@]\n",data);
}

- (void)registerWithCallback:(NSObject<LiveViewCallback> *)lvc {
	DebugLog(@"Started listening for Bluetooth notifications on channel %d", serverChannelID);
	incomingChannelNotification = [IOBluetoothRFCOMMChannel registerForChannelOpenNotifications:self selector:@selector(newRFCOMMChannelOpened:channel:)];
	callback=lvc;
}

- (void) newRFCOMMChannelOpened:(IOBluetoothUserNotification *)inNotification
                        channel:(IOBluetoothRFCOMMChannel *)newChannel {
	// Make sure the channel is an incoming channel on the right channel ID.
	DebugLog(@"Received connection on channel %d from 0x%x",[newChannel getChannelID],[[newChannel getDevice] getClassOfDevice]);
	if (newChannel != nil && [newChannel isIncoming] && [[newChannel getDevice] getClassOfDevice]==0x20fc) {
		rfcommChannel = newChannel;
		serverChannelID = [newChannel getChannelID];
		channelMTU = [newChannel getMTU];
		DebugLog(@"MTU is %d",channelMTU);
		
		// Retains the channel
		[rfcommChannel retain];
		
		// Set self as the channel's delegate: THIS IS THE VERY FIRST THING TO DO FOR A SERVER !!!!
		if ([rfcommChannel setDelegate:self] == kIOReturnSuccess) {
			
			NSMutableData *output = [[[NSMutableData alloc] init] autorelease];
			[output appendString:@"0.0.3"];
			[self sendMessage: kMessageGetCaps withData:output];

			// We're going to do the callback when we receive the getcaps message.
			// [callback newLiveViewConnection];
		} else {
			// The setDelegate: call failed. This is catastrophic for a server
			// Releases the channel:
			[rfcommChannel release];
			rfcommChannel = nil;
		}
	}
}

- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel*)rfcommChannelParam {
	rfcommChannel = nil;
	DebugLog(@"channel was closed");
	//	[self publishService];
}

- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)rfcommChannelParam data:(void *)dataPointer length:(size_t)dataLength {
	NSData *data = [NSData dataWithBytes:dataPointer length:dataLength];
	BluetoothRFCOMMChannelID cid=[rfcommChannelParam getChannelID];
	uint8_t msg;
	uint8_t headlen;
	uint32_t datalen;
	
	while ([data length]>=6) {
		[data getBytes:&msg range:NSMakeRange(0,1)];
		[data getBytes:&headlen range:NSMakeRange(1,1)];
		if (headlen==4) {
			[data getBytes:&datalen range:NSMakeRange(2,4)];
			datalen=ntohl(datalen);
			DebugLog(@"received message %d with data [%@] on channel id %d",msg,data, cid);
			[self handleLiveViewMessage:msg
								   withData:[data subdataWithRange:NSMakeRange(6,datalen)]];
			data = [data subdataWithRange:NSMakeRange(6+datalen, [data length]-6-datalen)];
		} else {
			DebugLog(@"received data [%@] on channel id %d",data, cid);
			[self handleRawNotification:data];
			data=[data subdataWithRange:NSMakeRange(0, 0)];
		}
	}
	if ([data length]>0) {
		DebugLog(@"received data [%@] on channel id %d",data, cid);
		[self handleRawNotification:data];
	}
	
}

- (void)rfcommChannelWriteComplete:(IOBluetoothRFCOMMChannel*)rfcommChannelParam refcon:(void*)refcon status:(IOReturn)error {
//	NSData *data=(NSData *)refcon;
	if (error != kIOReturnSuccess) DebugLog(@"Write complete status %d",error);
//	[data release];
}

- (void)sendData: (NSData *)data {
	if (rfcommChannel!=nil) {
		NSData *packet;
		int remain = [data length];
		while (channelMTU && remain > channelMTU) {
			packet = [data subdataWithRange:NSMakeRange(0, channelMTU)];
			remain -= channelMTU;
			data = [data subdataWithRange:NSMakeRange(channelMTU, remain)];
			[rfcommChannel writeAsync:(void*)[packet bytes] length:[packet length] refcon:nil];
			DebugLog(@"Wrote %d bytes",[packet length]);
		}
		if ([data length]) {
			[rfcommChannel writeAsync:(void*)[data bytes] length:[data length] refcon:nil];
			DebugLog(@"Wrote %d bytes",[data length]);
		}
	}
}

- (void)sendMessage: (LiveViewMessage_t)msg withData:(NSData *)data {
	if (rfcommChannel!=nil) {
		DebugLog(@"Sending message %d with data [%@]",msg,data);
		NSMutableData *output=[[[NSMutableData alloc] init] autorelease];
		[output appendint8:msg];
		[output appendint8:4];
		[output appendBEint32:[data length]];
		[output appendData:data];
		[self sendData:output];
	}
}

- (void)stop {
	// Stop listening to openNotifications.
	[incomingChannelNotification unregister];
	// Don't have to release?
	// [incomingChannelNotification release];
	// Close channel if open
	if ([rfcommChannel isOpen]) [rfcommChannel closeChannel];
	// Close underlying bluetooth connection
	[[rfcommChannel getDevice] closeConnection];
	// release it
	[rfcommChannel release];
	rfcommChannel = nil;
}

- (void)dealloc {
	// we retained some stuff
	[softwareVersion release];
	[menuItems removeAllObjects];
	[menuItems release];
	// this is why we nil rfcommChannel
	[rfcommChannel release];
	[super dealloc];
}

@end
