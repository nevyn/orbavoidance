/*
 *  CGS.h
 *  Vis1
 *
 *  Created by Joachim Bengtsson on 2009-05-06.
 *  Copyright 2009 Third Cog Software. All rights reserved.
 *
 */

// From http://iloveco.de/using-core-image-filters-onunder-a-nswindow/

typedef void * CGSConnection;
typedef void *CGSWindowFilterRef;
typedef int CGSWindowID;

extern OSStatus CGSNewConnection(const void **attributes, CGSConnection * id);
extern CGError CGSNewCIFilterByName(CGSConnection cid, CFStringRef filterName, CGSWindowFilterRef *outFilter);
extern CGError CGSSetCIFilterValuesFromDictionary(CGSConnection cid, CGSWindowFilterRef filter, CFDictionaryRef filterValues);
extern CGError CGSAddWindowFilter(CGSConnection cid, CGSWindowID wid, CGSWindowFilterRef filter, int flags);

#import <Cocoa/Cocoa.h>

void enableBlurOnWindow(NSWindow* w);
