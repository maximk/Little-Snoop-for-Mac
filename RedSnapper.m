//
//  RedSnapper.m
//  Little Snoop
//
//  Created by Natalia Ivanova on 13.06.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RedSnapper.h"

#import "Base64.h"

#define MAX_DISPLAYS 16

@implementation RedSnapper

-(NSString *)getScreensJson
{
	CGDirectDisplayID displayIDs[MAX_DISPLAYS];
	CGDisplayCount displayCount;
	CGGetActiveDisplayList(MAX_DISPLAYS, displayIDs, &displayCount);
	
	int jsonObjsCount = 0;
	NSString *jsonObjs[MAX_DISPLAYS];
	
	int i;
	for (i = 0; i < displayCount; i++)
	{
		CGDirectDisplayID displayID = displayIDs[i];
		CGRect rect = CGDisplayBounds(displayID);
		CGImageRef screenShot = CGWindowListCreateImage(rect,
			kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault);
		if (screenShot != NULL)
		{
			jsonObjs[jsonObjsCount] = [self makeJsonObj:screenShot];
			jsonObjsCount++;
		}
	}
	
	NSLog(@"%d screens captured\n", jsonObjsCount);
	
	NSMutableString *json = [NSMutableString stringWithCapacity:102400];
	[json appendString:@"["];
	for (i = 0; i < jsonObjsCount; i++)
	{
		if (i > 0)
			[json appendString:@","];
		[json appendString:jsonObjs[i]];
	}
	[json appendString:@"]"];
	
	return json;
}

-(NSString *)makeJsonObj:(CGImageRef)cgImage
{
	// Create a bitmap rep from the image...
	NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
	NSSize origPixels = NSMakeSize([bitmapRep pixelsWide], [bitmapRep pixelsHigh]);
	
	NSSize midPixels = [self getMidPixels:origPixels];
	float midFactorW = midPixels.width / origPixels.width;
	float midFactorH = midPixels.height / origPixels.height;
	
	NSSize thumbPixels = [self getThumbPixels:origPixels];
	float thumbFactorW = thumbPixels.width / origPixels.width;
	float thumbFactorH = thumbPixels.height / origPixels.height;

	// Create an NSImage...
	NSImage *image = [[NSImage alloc] init];
	[image addRepresentation:bitmapRep];
	[bitmapRep release];
	
	// Sizes in points
	NSSize origSize = [image size];
	NSSize midSize = NSMakeSize(origSize.width*midFactorW, origSize.height*midFactorH);
	NSSize thumbSize = NSMakeSize(origSize.width*thumbFactorW, origSize.height*thumbFactorH);
	
	// Create smaller image...
	NSImage *midImage = [[NSImage alloc] initWithSize:midSize];
	
	[midImage lockFocus];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

	[image drawInRect: NSMakeRect(0, 0, midSize.width, midSize.height)
		   fromRect: NSMakeRect(0, 0, origSize.width, origSize.height)
		   operation: NSCompositeSourceOver
		   fraction: 1.0];
	[midImage unlockFocus];
	
	NSBitmapImageRep *midRep = [[NSBitmapImageRep alloc] initWithData:[midImage TIFFRepresentation]];
	NSData *midPngData = [midRep representationUsingType:NSPNGFileType properties:nil];
	//[midPngData writeToFile:@"midPngData1.png" atomically:YES];

	// Create thumbnail image...
	NSImage *thumbImage = [[NSImage alloc] initWithSize:thumbSize];
	
	[thumbImage lockFocus];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

	[image drawInRect: NSMakeRect(0, 0, thumbSize.width, thumbSize.height)
		   fromRect: NSMakeRect(0, 0, origSize.width, origSize.height)
		   operation: NSCompositeSourceOver
		   fraction: 1.0];
	[thumbImage unlockFocus];
	
	NSBitmapImageRep *thumbRep = [[NSBitmapImageRep alloc] initWithData:[thumbImage TIFFRepresentation]];
	NSData *thumbPngData = [thumbRep representationUsingType:NSPNGFileType properties:nil];
	//[thumbPngData writeToFile:@"thumbPngData1.png" atomically:YES];
	
	NSMutableString *jsonObj = [NSMutableString stringWithCapacity:40960];
	[jsonObj appendFormat:@"{\"orig_width\":%d,\"orig_height\":%d,"
		"\"width\":%d,\"height\":%d,"
		"\"thumb_width\":%d,\"thumb_height\":%d,"
		"\"snapshot\":\"",
			(NSInteger)origPixels.width, (NSInteger)origPixels.height,
			(NSInteger)midPixels.width, (NSInteger)midPixels.height,
			(NSInteger)thumbPixels.width, (NSInteger)thumbPixels.height];
	[jsonObj appendString:[Base64 encode:midPngData]];
	[jsonObj appendString:@"\",\"thumbnail\":\""];
	[jsonObj appendString:[Base64 encode:thumbPngData]];
	[jsonObj appendString:@"\"}"];
	
	return jsonObj;
}

-(NSSize)getMidPixels:(NSSize)pixels
{
	NSSize s1 = NSMakeSize(1024, 768);
	NSSize r1 = NSMakeSize(320, 240);
	NSSize s2 = NSMakeSize(1280, 1024);
	NSSize r2 = NSMakeSize(320, 256);
	NSSize s3 = NSMakeSize(1440, 900);
	NSSize r3 = NSMakeSize(320, 200);
	
	if (NSEqualSizes(pixels, s1))
		return r1;
	if (NSEqualSizes(pixels, s2))
		return r2;
	if (NSEqualSizes(pixels, s3))
		return r3;
	
	//
	// Select closest aspect ratio -- unlike the current Windows version
	//
	
	float aspect = pixels.width / pixels.height;
	float d1 = fabs(s1.width / s1.height - aspect);
	float d2 = fabs(s2.width / s2.height - aspect);
	float d3 = fabs(s3.width / s3.height - aspect);
	
	if (d1 <= d2 && d1 <= d3)
		return r1;
	if (d2 <= d3)
		return r2;
	return r3;
}

-(NSSize)getThumbPixels:(NSSize)pixels
{
	NSSize s1 = NSMakeSize(1024, 768);
	NSSize r1 = NSMakeSize(80, 60);
	NSSize s2 = NSMakeSize(1280, 1024);
	NSSize r2 = NSMakeSize(80, 64);
	NSSize s3 = NSMakeSize(1440, 900);
	NSSize r3 = NSMakeSize(80, 50);
	
	if (NSEqualSizes(pixels, s1))
		return r1;
	if (NSEqualSizes(pixels, s2))
		return r2;
	if (NSEqualSizes(pixels, s3))
		return r3;
	
	//
	// Select closest aspect ratio -- unlike the current Windows version
	//
	
	float aspect = pixels.width / pixels.height;
	float d1 = fabs(s1.width / s1.height - aspect);
	float d2 = fabs(s2.width / s2.height - aspect);
	float d3 = fabs(s3.width / s3.height - aspect);
	
	if (d1 <= d2 && d1 <= d3)
		return r1;
	if (d2 <= d3)
		return r2;
	return r3;
}

@end
