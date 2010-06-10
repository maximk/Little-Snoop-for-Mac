//
//  SnoopOnMe.m
//  SnoopOnMe1
//
//  Created by Maxim Kharchenko on 5/18/09.
//  Copyright 2009 SITRONICS. All rights reserved.
//

#import "SnoopOnMe.h"
#import "ScreenShot.h"

@interface SnoopOnMe (PrivateMethods)
-(void)postIt:(NSData *)snapshot;
-(void)save:(NSData *)snapshot;
@end

@implementation SnoopOnMe (PrivateMethods)

-(void)postIt:(NSData *)bitmapData {

	//creating the url request:
	NSURL *addScrUrl = [NSURL URLWithString:@"http://localhost:8888/addscr.php"];
	//NSURL *addScrUrl = [NSURL URLWithString:@"http://snoopon.me/addscr.php"];
	NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:addScrUrl];
	
	//adding header information:
	[postRequest setHTTPMethod:@"POST"];
	
	NSString *stringBoundary = [NSString stringWithString:@"0xKhTmLbOuNdArY"];
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary];
	[postRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
	
	//setting up the body:
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"user\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"maximk"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"pwd\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"kmixam"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"imgdata\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	//[postBody appendData:[[NSString stringWithString:@"qqq"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:bitmapData];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postRequest setHTTPBody:postBody];

	//char reply[1];
	//NSData *data = [ NSURLConnection sendSynchronousRequest: postRequest returningResponse: nil error: nil ];
	//[data getBytes:reply length:1];
	
	[[htmlView mainFrame] loadRequest:postRequest];
}

-(void)save:(NSData *)snapshot {
	
}

@end


@implementation SnoopOnMe

@synthesize messageLabel;
@synthesize htmlView;
@synthesize imageView;

-(IBAction)snapIt:(id)sender {

	ScreenShot *shot = [[ScreenShot alloc] init];
	[shot readFullScreenToBuffer];
	
	NSImage *image = [shot getScreenImage];
	
	NSArray *representations;
	NSData *bitmapData;
	
	representations = [image representations];
	bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations 
														  usingType:NSJPEGFileType properties:nil];
	
	[bitmapData writeToFile:@"/Users/mk/Desktop/Snap1.jpg" atomically:YES];
	[self postIt:bitmapData];
	
	[shot release];

	[imageView setImage:image];
	[[self messageLabel] setStringValue:@"Snapped"];
}

@end
