//
//  RedSnapper.h
//  Little Snoop
//
//  Created by Natalia Ivanova on 13.06.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RedSnapper : NSObject {

}

-(NSString *)getScreensJson;
-(NSString *)makeJsonObj:(CGImageRef)cgImage;

-(NSSize)getMidPixels:(NSSize)pixels;
-(NSSize)getThumbPixels:(NSSize)pixels;

@end
