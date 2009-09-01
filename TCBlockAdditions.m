//
//  TCBlockAdditions.m
//  OrbAvoidance
//
//  Created by Joachim Bengtsson on 2009-09-02.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import "TCBlockAdditions.h"

@implementation NSArray (TCFunctionalArray)
-(NSArray*)filteredArray:(TCArrayFilter)filter;
{
	NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:[self count]];
	for (id obj in self) {
		if(filter(obj))
			[filtered addObject:obj];
	}
	return filtered;
}
@end