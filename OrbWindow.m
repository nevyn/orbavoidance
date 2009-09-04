//
//  OrbWindow.m
//  OrbAvoidance
//
//  Created by Joachim Bengtsson on 2009-09-01.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import "OrbWindow.h"
#import "TCBlockAdditions.h"

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
	
	[self setBackgroundColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.1]];
	
	[self setCollectionBehavior:NSWindowCollectionBehaviorStationary];

	
	TCAfter(0.01, ^ {
		NSInteger compositingType = 1 << 0; // Under the window
		/* Make a new connection to CoreGraphics */
		CGSNewConnection(NULL, &thisConnection);
		/* Create a CoreImage filter and set it up */
		CGSNewCIFilterByName(thisConnection, (CFStringRef)@"CIGaussianBlur", &compositingFilter);
		NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.0] forKey:@"inputRadius"];
		CGSSetCIFilterValuesFromDictionary(thisConnection, compositingFilter, (CFDictionaryRef)options);
		/* Now apply the filter to the window */
		CGSAddWindowFilter(thisConnection, [self windowNumber], compositingFilter, compositingType);
	});
		
	return self;
}
-(void)setBlur:(CGFloat)amount;
{
	if(!compositingFilter) return;
	
			NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:amount] forKey:@"inputRadius"];
		CGSSetCIFilterValuesFromDictionary(thisConnection, compositingFilter, (CFDictionaryRef)options);

}
@end
