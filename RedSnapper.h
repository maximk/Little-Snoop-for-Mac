//
//  RedSnapper.h
//  Little Snoop
//
//  Copyright 2010 Snoopon.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RedSnapper : NSObject {

}

-(NSString *)getScreensJson;
-(NSString *)makeJsonObj:(CGImageRef)cgImage;

-(NSSize)getMidPixels:(NSSize)pixels;
-(NSSize)getThumbPixels:(NSSize)pixels;

@end
