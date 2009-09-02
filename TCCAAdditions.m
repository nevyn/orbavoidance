//
//  TCCAAdditions.m
//  OrbAvoidance
//
//  Created by Joachim Bengtsson on 2009-09-01.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import "TCCAAdditions.h"





@implementation CALayer (VectorAddition)
-(Vector2*)positionVector;
{
	return [Vector2 vectorWithCGPoint:self.position];
}
-(void)setPositionVector:(Vector2*)vector;
{
	self.position = vector.CGPoint;
}
@end


@implementation CATransaction (DisableAnimations)

+(void)withoutAnimations:(void (^)())do_;
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
  	               forKey:kCATransactionDisableActions];
	do_();
	
	[CATransaction commit];
}
+(void)withAnimations:(void (^)())do_;
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanFalse
  	               forKey:kCATransactionDisableActions];
	do_();
	
	[CATransaction commit];
}

+(void)withAnimationSpeed:(NSTimeInterval)speed :(void (^)())do_;
{
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:speed]
  	               forKey:kCATransactionAnimationDuration];
	do_();
	
	[CATransaction commit];
}
@end
