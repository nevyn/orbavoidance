//
//  TCBlockAdditions.h
//  OrbAvoidance
//
//  Created by Joachim Bengtsson on 2009-09-02.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef BOOL (^TCArrayFilter) (id obj);

@interface NSArray (TCFunctionalArray)
-(NSArray*)filteredArray:(TCArrayFilter)filter;
@end