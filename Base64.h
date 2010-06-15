//
//  Base64.h
//  Little Snoop
//
//  Copyright 2010 Snoopon.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Base64 : NSObject {
}

+ (void) initialize;
+ (NSString*) encode:(const uint8_t*) input length:(NSInteger) length;
+ (NSString*) encode:(NSData*) rawBytes;
+ (NSData*) decode:(const char*) string length:(NSInteger) inputLength;
+ (NSData*) decode:(NSString*) string;

@end
