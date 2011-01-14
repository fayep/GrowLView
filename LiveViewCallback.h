//
//  LiveViewCallback.h
//  GrowLView
//
//  Created by Faye Pearson on 14/01/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>

typedef enum {
	kMessageGetCaps			= 1,
	kMessageGetCaps_Resp,	// Received
	
	kMessageDisplayText,
	kMessageDisplayText_Resp,
	
	kMessageDisplayPanel,
	kMessageDisplayPanel_Resp,
	
	kMessageDeviceStatus,
	kMessageDeviceStatus_Resp,	//received
	
	kMessageDisplayBitmap	= 19,
	kMessageDisplayBitmap_Resp,
	
	kMessageClearDisplay,
	kMessageClearDisplay_Resp,
	
	kMessageSetMenuSize,
	kMessageSetMenuSize_Resp,
	
	kMessageGetMenuItem,	// Received?
	kMessageGetMenuItem_Resp,
	
	kMessageGetAlert,
	kMessageGetAlert_Resp,
	
	kMessageNavigation,
	kMessageNavigation_Resp,
	
	kMessageSetStatusBar	= 33,
	kMessageSetStatusBar_Resp,
	
	kMessageGetMenuItems, // Received
	
	kMessageSetMenuSettings,
	kMessageSetMenuSettings_Resp,
	
	kMessageGetTime,
	kMessageGetTime_Resp,
	
	kMessageSetLED,
	kMessageSetLED_Resp,	// received
	
	kMessageSetVibrate,
	kMessageSetVibrate_Resp,	// received
	
	kMessageAck,
	
	kMessageSetScreenMode	= 64,
	kMessageSetScreenMode_Resp,	// Received
	
	kMessageGetScreenMode,
	kMessageGetScreenMode_Resp
} LiveViewMessage_t;

typedef enum {
	kDeviceStatusOff,
	kDeviceStatusOn,
	kDeviceStatusMenu
} LiveViewStatus_t;

typedef enum {
	kResultOK,
	kResultError,
	kResultOOM,
	kResultExit,
	kResultCancel
} LiveViewResult_t;

typedef enum {
	kActionPress,
	kActionLongPress,
	kActionDoublePress,
} LiveViewNavAction_t;

typedef enum {
	kNavUp,
	kNavDown,
	kNavLeft,
	kNavRight,
	kNavSelect,
	kNavMenuSelect
} LiveViewNavType_t;

typedef enum {
	kAlertCurrent,
	kAlertFirst,
	kAlertLast,
	kAlertNext,
	kAlertPrev
} LiveViewAlert_t;

typedef enum {
	kBrightnessOff	= 48,
	kBrightnessDim,
	kBrightnessMax
} LiveViewBrightness_t;

@protocol LiveViewCallback
- (void)newLiveViewConnection;
- (void)handleLiveViewNavigation:(int)navigation;
- (void)handleLiveViewDeviceStatus:(int)status;

@end
