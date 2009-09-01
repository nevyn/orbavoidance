//
//  OrbWindow.m
//  OrbAvoidance
//
//  Created by Joachim Bengtsson on 2009-09-01.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import "OrbWindow.h"


@implementation OrbWindow
- (id)initWithContentRect:(NSRect)contentRect
								styleMask:(NSUInteger)aStyle
									backing:(NSBackingStoreType)bufferingType
										defer:(BOOL)flag;
{
	self = [super initWithContentRect:contentRect
												 styleMask: NSBorderlessWindowMask
													 backing: bufferingType
														 defer: flag];
	if( ! self ) return nil;
	
	[self setLevel:NSScreenSaverWindowLevel];
	
	[self setFrame:[[NSScreen mainScreen] frame] display:YES];
	
	[self setIgnoresMouseEvents:YES];
	[self setBackgroundColor:[NSColor clearColor]];
	[self setOpaque:NO];
		
	return self;
}
@end
