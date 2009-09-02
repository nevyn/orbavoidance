/*
 *  CGS.m
 *  Vis1
 *
 *  Created by Joachim Bengtsson on 2009-05-06.
 *  Copyright 2009 Third Cog Software. All rights reserved.
 *
 */
#include "CGS.h"

void enableBlurOnWindow(NSWindow* w)
{
	if([w isOpaque]) {
		[w setBackgroundColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.2]];
		[w setOpaque:NO];
	}
	
	CGSConnection thisConnection;
	CGSWindowFilterRef compositingFilter;
	/*
	 Compositing Types
	 Under the window   = 1 <<  0
	 Over the window    = 1 <<  1
	 On the window      = 1 <<  2
	 */
	NSInteger compositingType = 1 << 0; // Under the window
	/* Make a new connection to CoreGraphics */
	CGSNewConnection(NULL, &thisConnection);
	/* Create a CoreImage filter and set it up */
	CGSNewCIFilterByName(thisConnection, (CFStringRef)@"CIGaussianBlur", &compositingFilter);
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:3.0] forKey:@"inputRadius"];
	CGSSetCIFilterValuesFromDictionary(thisConnection, compositingFilter, (CFDictionaryRef)options);
	/* Now apply the filter to the window */
	CGSAddWindowFilter(thisConnection, [w windowNumber], compositingFilter, compositingType);
		
}
