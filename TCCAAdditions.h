//
//  TCCAAdditions.h
//  OrbAvoidance
//
//  Created by Joachim Bengtsson on 2009-09-01.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "Vector2.h"

@interface CALayer (VectorAddition)
-(Vector2*)positionVector;
-(void)setPositionVector:(Vector2*)vector;
@end

@interface CATransaction (DisableAnimations)
+(void)withoutAnimations:(void (^)())do_;
@end