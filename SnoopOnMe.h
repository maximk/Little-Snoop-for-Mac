//
//  SnoopOnMe.h
//  SnoopOnMe1
//
//  Created by Maxim Kharchenko on 5/18/09.
//  Copyright 2009 SITRONICS. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface SnoopOnMe : NSObject {
	IBOutlet NSTextField *messageLabel;
	IBOutlet WebView *htmlView;
	IBOutlet NSImageView *imageView;
}

-(IBAction)snapIt:(id)sender;

@property (nonatomic, retain) NSTextField *messageLabel;
@property (nonatomic, retain) WebView *htmlView;
@property (nonatomic, retain) NSImageView *imageView;

@end
