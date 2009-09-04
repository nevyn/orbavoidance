//
//  TCBlockAdditions.h
//  OrbAvoidance
//
//  Created by Joachim Bengtsson on 2009-09-02.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef BOOL (^TCArrayFilter) (id obj);
typedef id (^TCArrayFolder) (id folder, id element);

@interface NSArray (TCFunctionalArray)
-(NSArray*)filteredArray:(TCArrayFilter)filter;
-(NSArray*)map:(id(^)(id))mapper;
-(id)foldInitialValue:(id)initial with:(TCArrayFolder)folder;
@end

extern void TCAfter(NSTimeInterval interval, dispatch_block_t do_);