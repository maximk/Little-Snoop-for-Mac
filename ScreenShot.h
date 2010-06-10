//
//  ScreenShot.h
//  SnoopOnMe1
//
//  Created by Maxim Kharchenko on 5/18/09.
//  Copyright 2009 Snoop On Me. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@interface ScreenShot : NSObject {
	NSOpenGLContext *mGLContext;
    void *mData;
    long mByteWidth, mWidth, mHeight;	
}

- (void) readPartialScreenToBuffer: (size_t) width bufferHeight:(size_t) height bufferBaseAddress: (void *) baseAddress;
- (void) readFullScreenToBuffer;
- (NSData *) getScreeenBuffer;
- (NSImage *) getScreenImage;

@end
