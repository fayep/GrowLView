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


@implementation LiveView

- (void)addMenuItem:(LVMenuItem *)item {
	if (menuItems==nil) {
		menuItems = [[NSMutableArray alloc] init];
	}
	[item retain];
	[menuItems addObject:item];
}
- (void)sendMenuItemResponse:(int)number item:(LVMenuItem *)item {
	NSMutableData *output = [[[NSMutableData alloc] init] autorelease];
	[output appendint8:![item isAlertItem]];
	[output appendBEint16:0];
	[output appendBEint16:[item unreadCount]];
	[output appendBEint16:0];
	[output appendint8:number+3];
	[output appendint8:0];
	[output appendBEint16:0];
	[output appendBEint16:0];
	[output appendBigString:[item title]];
	[output appendData:[item image]];
	NSLog(@"Sending item %@",[item title]);
	[self sendMessage:kMessageGetMenuItem_Resp withData:output];
}	

- (void)handleLiveViewMessage:(LiveViewMessage_t)msg withData:(NSData *)data {
	NSMutableData *output = [[[NSMutableData alloc] init] autorelease];
	int number = 0;
	int c;
	[output appendint8:msg];
	[self sendMessage:kMessageAck withData:output];
	switch (msg) {
		case kMessageGetCaps_Resp:
			//			80 80 13 13 30 30 13 13 32 00 05 302e302e35 (0.0.5)
			[data getBytes:&width  range:NSMakeRange(0, 1)];
			[data getBytes:&height range:NSMakeRange(1, 1)];
			[data getBytes:&statusBarWidth  range:NSMakeRange(2, 1)];
			[data getBytes:&statusBarHeight range:NSMakeRange(3, 1)];
			[data getBytes:&viewWidth  range:NSMakeRange(4, 1)];
			[data getBytes:&viewHeight range:NSMakeRange(5, 1)];
			[data getBytes:&announceWidth  range:NSMakeRange(6, 1)];
			[data getBytes:&announceHeight range:NSMakeRange(7, 1)];
			[data getBytes:&textChunkSize range:NSMakeRange(8, 1)];
			[data getBytes:&idleTimer range:NSMakeRange(9, 1)];
			[data getBytes:&number range:NSMakeRange(10, 1)];
			softwareVersion = [[NSString alloc]
							   initWithData:[data
											 subdataWithRange:NSMakeRange(11, number)]
							   encoding:NSASCIIStringEncoding];
			if (idleTimer!=0) {
				NSLog(@"DisplayCapabilities with non-zero idle timer %d", idleTimer);
			}
			NSLog(@"Connection from LiveView with Version %@", softwareVersion);
			[callback newLiveViewConnection];
			[output setLength:0];
			[output appendint8:[menuItems count]];
			[self sendMessage:kMessageSetMenuSize withData: output];
		case kMessageGetMenuItems:
			[data getBytes:&number range:NSMakeRange(0, 1)];
			switch (number) {
				case 0:
					[output setLength:0];
					for (c=0;c<[menuItems count]; c++)
						[self sendMenuItemResponse:c item:[menuItems objectAtIndex:c]];
					break;
				default:
					break;
			}
			break;
		case kMessageGetAlert:
			[data getBytes:&number range:NSMakeRange(0,1)];
			[output setLength:0];
			[self sendMessage:kMessageGetAlert_Resp withData:output];
			break;
			
		case kMessageSetStatusBar_Resp:
			[output setLength:0];
			[output appendint8:5];
			[output appendint8:12];
			[output appendint8:0];
			[self sendMessage:kMessageSetMenuSettings withData:output];
			
		case kMessageGetTime:
			[output setLength:0];
			[output appendBEint32:[[[NSDate alloc] init] timeIntervalSince1970]];
			[output appendint8:0];
			[self sendMessage:kMessageGetTime_Resp withData:output];
			
		case kMessageDeviceStatus:
			[output setLength:0];
			[output appendint8:kResultOK];
			[self sendMessage:kMessageDeviceStatus_Resp withData:output];
			break;
			
		case kMessageNavigation:
			[output setLength:0];
			[output appendint8:kResultExit];
			[self sendMessage:kMessageNavigation_Resp withData:output];
			break;
		default:
			NSLog(@"Message %d with data [%@]\n", msg, data);
			break;
	}
}

- (void)handleRawNotification:(NSData *)data {
	NSLog(@"Unknown data [%@]\n",data);
}

- (void)registerWithCallback:(NSObject<LiveViewCallback> *)lvc {
	incomingChannelNotification = [IOBluetoothRFCOMMChannel registerForChannelOpenNotifications:self selector:@selector(newRFCOMMChannelOpened:channel:)];
	NSLog(@"Started listening for Bluetooth notifications on channel %d", serverChannelID);
	callback=lvc;
}

- (void) newRFCOMMChannelOpened:(IOBluetoothUserNotification *)inNotification
                        channel:(IOBluetoothRFCOMMChannel *)newChannel {
	// Make sure the channel is an incoming channel on the right channel ID.
	NSLog(@"Received connection on channel %d from 0x%x",[newChannel getChannelID],[[newChannel getDevice] getClassOfDevice]);
	if (newChannel != nil && [newChannel isIncoming] && [[newChannel getDevice] getClassOfDevice]==0x20fc) {
		rfcommChannel = newChannel;
		serverChannelID = [newChannel getChannelID];
		channelMTU = [newChannel getMTU];
		NSLog(@"MTU is %d",channelMTU);
		
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
	NSLog(@"channel was closed");
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
			NSLog(@"received message %d with data [%@] on channel id %d",msg,data, cid);
			[self handleLiveViewMessage:msg
								   withData:[data subdataWithRange:NSMakeRange(6,datalen)]];
			data = [data subdataWithRange:NSMakeRange(6+datalen, [data length]-6-datalen)];
		} else {
			NSLog(@"received data [%@] on channel id %d",data, cid);
			[self handleRawNotification:data];
			data=[data subdataWithRange:NSMakeRange(0, 0)];
		}
	}
	if ([data length]>0) {
		NSLog(@"received data [%@] on channel id %d",data, cid);
		[self handleRawNotification:data];
	}
	
}

- (void)rfcommChannelWriteComplete:(IOBluetoothRFCOMMChannel*)rfcommChannelParam refcon:(void*)refcon status:(IOReturn)error {
//	NSData *data=(NSData *)refcon;
	if (error != kIOReturnSuccess) NSLog(@"Write complete status %d",error);
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
			NSLog(@"Wrote %d bytes",[packet length]);
		}
		if ([data length]) {
			[rfcommChannel writeAsync:(void*)[data bytes] length:[data length] refcon:nil];
			NSLog(@"Wrote %d bytes",[data length]);
		}
	}
}

- (void)sendMessage: (LiveViewMessage_t)msg withData:(NSData *)data {
	if (rfcommChannel!=nil) {
		NSLog(@"Sending message %d with data [%@]",msg,data);
		NSMutableData *output=[[[NSMutableData alloc] init] autorelease];
		[output appendint8:msg];
		[output appendint8:4];
		[output appendBEint32:[data length]];
		[output appendData:data];
		[self sendData:output];
	}
}

- (void)stop {
	[incomingChannelNotification unregister];
	[incomingChannelNotification release];
	[rfcommChannel release];
	rfcommChannel = nil;
}

- (void)dealloc {
	[softwareVersion release];
	[menuItems release];
	[incomingChannelNotification release];
	[rfcommChannel release];
	[super dealloc];
}

@end
