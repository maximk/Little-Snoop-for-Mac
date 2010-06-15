//
//  LittleSnoopController.m
//  Little Snoop
//
//  Created by Natalia Ivanova on 12.06.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LittleSnoopController.h"

#import "RedSnapper.h"

@implementation LittleSnoopController

@synthesize littleSnoopId;
@synthesize captureHost;
@synthesize capturePort;
@synthesize capturePath;
@synthesize settingsPath;
@synthesize installedPath;
@synthesize portaPath;
	
@synthesize enabled;
@synthesize schedule;

@synthesize firstTimeWindow;

- (id) init {
 
    self = [super init];
    if (self) {
        NSString *errorDesc = nil;
        NSPropertyListFormat format;
        NSString *plistPath;
        NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
           NSUserDomainMask, YES) objectAtIndex:0];
        plistPath = [rootPath stringByAppendingPathComponent:@"Settings.plist"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            plistPath = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"];
        }
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        NSMutableDictionary *temp = (NSMutableDictionary *)[NSPropertyListSerialization
            propertyListFromData:plistXML
            mutabilityOption:NSPropertyListMutableContainersAndLeaves
            format:&format
            errorDescription:&errorDesc];
        if (!temp) {
            NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
        }
		
		self.littleSnoopId = [temp objectForKey:@"LsId"];
		if ([self.littleSnoopId length] == 0)
		{
			CFStringRef uuid = CFUUIDCreateString(NULL, CFUUIDCreate(NULL));
			self.littleSnoopId = (NSString *)uuid;
			
			//
			// DONE: Update Settings.plist
			//
			
			[temp setObject:self.littleSnoopId forKey:@"LsId"];
			[temp writeToFile:plistPath atomically:YES];
		}

        self.captureHost = [temp objectForKey:@"CaptureHost"];
		self.capturePort = [[temp objectForKey:@"CapturePort"] integerValue];
		self.capturePath = [temp objectForKey:@"CapturePath"];
		self.settingsPath = [temp objectForKey:@"SettingsPath"];
		self.installedPath = [temp objectForKey:@"InstalledPath"];
		self.portaPath = [temp objectForKey:@"PortaPath"];
		
		self.enabled = 1;
		self.schedule = 5;
		
		//
		//	Start capture timer
		//
		
		NSTimeInterval secs = self.schedule; //*60;
		[NSTimer scheduledTimerWithTimeInterval:secs
			target:self selector:@selector(heartBeat:) userInfo:nil repeats:YES];
		
		// First Time Window may be shown many times
		[self.firstTimeWindow setReleasedWhenClosed:YES];
    }
    return self;
}

-(void)heartBeat:(NSTimer *)timer
{
	NSLog(@"Heart Beat\n");
	
	if ([self updateSettings])
	{
		if (self.enabled)
		{
			NSString *screensJson = [[RedSnapper alloc] getScreensJson];
			[self postScreens:screensJson];
		}
	}
	
	NSTimeInterval secs = self.schedule*60;
	if (secs != [timer timeInterval])
	{
		[timer invalidate];
		[NSTimer scheduledTimerWithTimeInterval:secs
			target:self selector:@selector(heartBeat:) userInfo:nil repeats:YES];		
	}
}

-(BOOL)updateSettings
{
	NSString *location = [[NSString alloc] initWithFormat:@"http://%@:%d%@/%@",
		self.captureHost, self.capturePort, self.settingsPath, self.littleSnoopId];
	
	NSLog(@"Reading settings from: %@\n", location);
	
	NSURLRequest *request = [NSURLRequest 
		requestWithURL:[NSURL URLWithString:location]
		cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
		timeoutInterval:20];
	
	NSHTTPURLResponse *response = nil;
	NSError *err = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request
		returningResponse:&response error:&err];
	if ([response statusCode] == 404)
	{
		//
		// DONE: Show the first time configuration dialog
		//
		
		[self.firstTimeWindow makeKeyAndOrderFront:self];
		return FALSE;
	}
	
	if (err != NULL)
	{
		NSLog(@"Unable to read settings\n");
		return FALSE;
	}
	
	NSString *reply = [[NSString alloc] initWithData:data
		encoding:NSASCIIStringEncoding];
	NSLog(@"Settings: %@\n", reply);
	
	NSInteger e = [[self getJsonValue:reply anchor:@"\"enabled\""] integerValue];
	NSInteger s = [[self getJsonValue:reply anchor:@"\"schedule\""] integerValue];
	
	if (s == 0)
		return FALSE;
	
	self.enabled = e;
	self.schedule = s;
	NSLog(@"e: %d; s: %d\n", self.enabled, self.schedule);
	
	return TRUE;
}

-(void)postScreens:(NSString *)screensJson
{
	NSLog(@"postScreens: %d byte(s)\n", [screensJson length]);
	//NSLog(@"postScreens: %@\n", screensJson);
	
	NSString *location = [[NSString alloc] initWithFormat:@"http://%@:%d%@",
		self.captureHost, self.capturePort, self.capturePath];
	NSLog(@"Posting screens to %@\n", location);

	NSMutableURLRequest *postRequest = [NSMutableURLRequest 
		requestWithURL:[NSURL URLWithString:location]
		cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
		timeoutInterval:60];
	[postRequest setHTTPMethod:@"POST"];
	
	NSMutableString *body = [NSMutableString stringWithCapacity:102400];
	[body appendFormat:@"{\"ls_id\":\"%@\",\"screens\":", self.littleSnoopId];
	[body appendString:screensJson];
	[body appendString:@"}"];
	[postRequest setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
	
	[NSURLConnection sendSynchronousRequest:postRequest
		returningResponse:nil error:nil];
}

-(NSString *)getJsonValue:(NSString *)json anchor:(NSString *)anchor
{
	NSRange r = [json rangeOfString:anchor];
	if (r.location == NSNotFound)
		return @"";
	if ([json characterAtIndex:r.location+r.length] != ':')
		return @"";
	NSString *tail = [json substringFromIndex:r.location+r.length+1];
	
	NSRange e1 = [tail rangeOfString:@","];
	NSRange e2 = [tail rangeOfString:@"}"];
	if (e1.location == NSNotFound && e2.location == NSNotFound)
		return @"";
	NSRange e;
	if (e1.location == NSNotFound)
		e = e2;
	else if (e2.location == NSNotFound)
		e = e1;
	else if (e1.location > e2.location)
		e = e2;
	else
		e = e1;
	
	return [tail substringToIndex:e.location];
}

-(void)openJustInstalled:(id)sender
{
	NSString *location;
	if (self.capturePort == 80)
		location = [[NSString alloc] initWithFormat:@"http://%@%@?ls_id=%@",
			self.captureHost, self.installedPath, self.littleSnoopId];
	else
		location = [[NSString alloc] initWithFormat:@"http://%@:%d%@?ls_id=%@",
			self.captureHost, self.capturePort, self.installedPath, self.littleSnoopId];

	NSLog(@"Opening Safari for %@\n", location);	
	[[NSWorkspace alloc] openURL:[NSURL URLWithString:location]];

	[self.firstTimeWindow close];
}

-(void)remindMeLater:(id)sender
{
	[self.firstTimeWindow close];
}

-(void)goToSnoopOnMe:(id)sender
{
	NSString *location;
	if (self.capturePort == 80)
		location = [[NSString alloc] initWithFormat:@"http://%@%@?ls_id=%@",
			self.captureHost, self.portaPath, self.littleSnoopId];
	else
		location = [[NSString alloc] initWithFormat:@"http://%@:%d%@?ls_id=%@",
			self.captureHost, self.capturePort, self.portaPath, self.littleSnoopId];

	NSLog(@"Opening Safari for %@\n", location);	
	[[NSWorkspace alloc] openURL:[NSURL URLWithString:location]];

	[self.firstTimeWindow close];
}

-(void)openSettings:(id)sender
{
	NSString *location;
	if (self.capturePort == 80)
		location = [[NSString alloc] initWithFormat:@"http://%@%@?ls_id=%@&room=settings",
			self.captureHost, self.portaPath, self.littleSnoopId];
	else
		location = [[NSString alloc] initWithFormat:@"http://%@:%d%@?ls_id=%@&room=settings",
			self.captureHost, self.capturePort, self.portaPath, self.littleSnoopId];

	NSLog(@"Opening Safari for %@\n", location);	
	[[NSWorkspace alloc] openURL:[NSURL URLWithString:location]];

	[self.firstTimeWindow close];
}

@end
