//
//  LittleSnoopController.h
//  Little Snoop
//
//  Created by Natalia Ivanova on 12.06.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//TCHAR g_szLittleSnoopId[MAX_OPT_STRING];
//TCHAR g_szCaptureHost[MAX_OPT_STRING];
//int g_nCapturePort;
//TCHAR g_szCapturePath[MAX_OPT_STRING];
//TCHAR g_szSettingsPath[MAX_OPT_STRING];
//TCHAR g_szInstalledPath[MAX_OPT_STRING];
//TCHAR g_szPortaPath[MAX_OPT_STRING];
//
//int g_nEnabled;
//int g_nSchedule;

@interface LittleSnoopController : NSObject {

	NSString *littleSnoopId;
	NSString *captureHost;
	NSInteger capturePort;
	NSString *capturePath;
	NSString *settingsPath;
	NSString *installedPath;
	NSString *portaPath;
	
	NSInteger enabled;
	NSInteger schedule;
	
	IBOutlet NSWindow *firstTimeWindow;
}

@property(copy, nonatomic) NSString *littleSnoopId;
@property(copy, nonatomic) NSString *captureHost;
@property(readwrite, nonatomic) NSInteger capturePort;
@property(copy, nonatomic) NSString *capturePath;
@property(copy, nonatomic) NSString *settingsPath;
@property(copy, nonatomic) NSString *installedPath;
@property(copy, nonatomic) NSString *portaPath;
	
@property(readwrite, nonatomic) NSInteger enabled;
@property(readwrite, nonatomic) NSInteger schedule;

@property(retain, nonatomic) NSWindow *firstTimeWindow;

-(IBAction)remindMeLater:(id)sender;
-(IBAction)openJustInstalled:(id)sender;
-(IBAction)goToSnoopOnMe:(id)sender;
-(IBAction)openSettings:(id)sender;

-(BOOL)updateSettings;
-(NSString *)getJsonValue:(NSString *)json anchor:(NSString *)anchor;
-(void)postScreens:(NSString *)screensJson;

@end
