//
//  OrbView.h
//  OrbAvoidance
//
//  Created by Joachim Bengtsson on 2009-09-01.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "Vector2.h"
#import "TCCAAdditions.h"
#import "TCSound.h"


@interface OrbView : NSView <NSSoundDelegate> {
	NSTimer *timer;
	NSTimeInterval lastUpdate;
	uint32_t level;
	float score;
	float multiplier;
	CAGradientLayer *multiplierIndicator;
	
	CAEmitterCell *ignition, *explosionCell;
	
	TCSound *suspense;
	
	// Format: [[name, score], [name score], ...] with at most 10 entries
	NSArray *highscores;
	
	CALayer *fillLayer;
	CAGradientLayer *highscoreLayer;
	CATextLayer *highscoreNamesLayer;
	CATextLayer *highscoreScoresLayer;
}
-(NSArray*)orbs;
-(NSArray*)squares;

-(void)explodeAt:(CGPoint)p;

-(void)clear;
-(void)levelUp;
@property float score;
@property float multiplier;
@property (assign) NSArray *highscores;
@end

@interface Orb : CALayer {
	CGFloat orbSpeed;
	Vector2 *velocity;
	Vector2 *acceleration;
}
+(Orb*)yellowOrb; // very slow
+(Orb*)redOrb; // slow
+(Orb*)purpleOrb; // medium
+(Orb*)blueOrb; // fast
+(Orb*)randomOrb;
-(id)initWithColor:(CGColorRef)color_ speed:(CGFloat)speed_;

-(void)update:(NSTimeInterval)dt;


@property (readonly) CGFloat orbSpeed;
@property (readwrite, retain) Vector2 *velocity;
@property (readwrite, retain) Vector2 *acceleration;

@end

@interface Square : CALayer {
	BOOL dangerous;
}
+(Square*)square;
@property BOOL dangerous;
@end