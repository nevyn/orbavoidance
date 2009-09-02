//
//  OrbWindow.h
//  OrbAvoidance
//
//  Created by Joachim Bengtsson on 2009-09-01.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CGS.h"

@interface OrbWindow : NSWindow {
	CGSConnection thisConnection;
	CGSWindowFilterRef compositingFilter;
}
-(void)setBlur:(CGFloat)amount;
@end
