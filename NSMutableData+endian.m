//
//  NSMutableData+endian.m
//  LiveView
//
//  Created by Faye Pearson on 09/01/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSMutableData+endian.h"


@implementation NSMutableData (endian)

- (void)appendint8:(int8_t)i8 {
	[self appendBytes:&i8 length:sizeof(int8_t)];
}

- (void)appendBEint16:(int16_t)i16 {
	i16=ntohs(i16);
	[self appendBytes:&i16 length:sizeof(int16_t)];
}

- (void)appendBEint32:(int32_t)i32 {
	i32=ntohl(i32);
	[self appendBytes:&i32 length:sizeof(int32_t)];
}

- (void)appendString:(NSString *)s {
	NSData *str = [s dataUsingEncoding:NSUTF8StringEncoding];
	if ([str length]>255) {
		str = [str subdataWithRange:NSMakeRange(0, 255)];
	}
	[self appendint8:[str length]];
	[self appendData:str];
}

- (void)appendBigString:(NSString *)s {
	NSData *str = [s dataUsingEncoding:NSUTF8StringEncoding];
	[self appendBEint16:[str length]];
	[self appendData:str];
}
@end
