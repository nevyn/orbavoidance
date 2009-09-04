//
//  OrbView.m
//  OrbAvoidance
//
//  Created by Joachim Bengtsson on 2009-09-01.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import "OrbView.h"
#import "TCBlockAdditions.h"
#import "OrbWindow.h"
#import "JSON.h"
#import "CollectionUtils.h"

#define ColRGBA(R, G, B, A) (CGColorRef)CFMakeCollectable(CGColorCreateGenericRGB(R, G, B, A))
#define ColRGBA2(R, G, B, A) ((id)ColRGBA(R, G, B, A))

static float frandom() {
	return random()/(float)RAND_MAX;
}

static float kSuspenseMultiplier = 10.;

@interface OrbView ()
-(void)updateHighscores;
-(void)blinkToColor:(CGColorRef)col;
-(void)cycleHighscoreColors;
@end

@implementation OrbView

+(void)initialize;
{
	srandom(time(NULL));
}

- (id)initWithFrame:(NSRect)frame {
	if( ! [super initWithFrame:frame] ) return nil;
	
	self.wantsLayer = YES;
	
	// For when things heat up
	fillLayer = [CALayer layer];
	fillLayer.frame = TCOriginRect(self.layer.frame);
	[self.layer addSublayer:fillLayer];
	fillLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
	fillLayer.backgroundColor = ColRGBA(0, 0, 0, 0);
	
	suspense = [TCSound soundNamed:@"Suspense.wav"];
	suspense.loops = YES;
	
	
	// Start a new level
	
	[self clear];	
	[self levelUp];
	
	// Heartbeat timer
	timer = [NSTimer scheduledTimerWithTimeInterval:1./60. target:self selector:@selector(update) userInfo:nil repeats:YES];
	lastUpdate = [NSDate timeIntervalSinceReferenceDate];
	
	
	// Online highscores are shown on the right side of the screen
	highscoreLayer = [CAGradientLayer layer];
	
	CGFloat w = [NSScreen mainScreen].frame.size.width, h = [NSScreen mainScreen].frame.size.height;
	highscoreLayer.frame = CGRectMake(0.6*w, 0.1*h, 0.35*w, 0.8*h);

	highscoreLayer.startPoint = CGPointMake(0, 1);
	highscoreLayer.endPoint = CGPointMake(0, 0);
	[self cycleHighscoreColors];
	
	
	CALayer *highscoreTextParent = [CALayer layer];
	highscoreTextParent.frame = TCOriginRect(highscoreLayer.frame);
	
	highscoreNamesLayer = [CATextLayer layer];
	highscoreNamesLayer.fontSize = 20;
	highscoreNamesLayer.string = [NSString stringWithFormat:@""];
	highscoreNamesLayer.frame = CGRectMake(0, 0, highscoreLayer.frame.size.width/2, highscoreLayer.frame.size.height);
	highscoreNamesLayer.shadowOpacity = 1.0;
	highscoreNamesLayer.shadowRadius = 4.0;
	highscoreNamesLayer.shadowOffset = CGSizeMake(4, -4);
	highscoreNamesLayer.alignmentMode = kCAAlignmentRight;
	
	highscoreScoresLayer = [CATextLayer layer];
	highscoreScoresLayer.fontSize = 20;
	highscoreScoresLayer.string = [NSString stringWithFormat:@""];
	highscoreScoresLayer.frame = CGRectMake(highscoreLayer.frame.size.width/2 + 20, 0, highscoreLayer.frame.size.width/2 - 20, highscoreLayer.frame.size.height);
	highscoreScoresLayer.shadowOpacity = 1.0;
	highscoreScoresLayer.shadowRadius = 4.0;
	highscoreScoresLayer.shadowOffset = CGSizeMake(4, -4);
	
	
	[highscoreTextParent addSublayer:highscoreNamesLayer];
	[highscoreTextParent addSublayer:highscoreScoresLayer];

	highscoreLayer.mask = highscoreTextParent;

	[self.layer addSublayer:highscoreLayer];
	
		// Fetch scores from the 'net
	self.highscores = [NSArray array];
	[self updateHighscores];
	
		// And do it every 30s
	[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(updateHighscores) userInfo:nil repeats:YES];


	
	// Prepare the explosion sprites
	
	const char* fileName = [[[NSBundle mainBundle] pathForResource:@"tspark" ofType:@"png"] UTF8String];
	CGDataProviderRef dataProvider = (CGDataProviderRef)CFMakeCollectable(CGDataProviderCreateWithFilename(fileName));
	id img = (id) CFMakeCollectable(CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault));
	explosionCell = [CAEmitterCell emitterCell];
	explosionCell.contents = img;
	explosionCell.birthRate = 4000;
	explosionCell.scale = 0.6;
	explosionCell.velocity = 130;
	explosionCell.lifetime = 2;
	explosionCell.alphaSpeed = -0.2;
	explosionCell.beginTime = 0;
	explosionCell.duration = 0.1;
	explosionCell.emissionRange = 2 * M_PI;
	explosionCell.scaleSpeed = -0.1;
	explosionCell.spin = 2;
	
	ignition = [CAEmitterCell emitterCell];
	ignition.lifetime = 0.05;
	ignition.birthRate = 1.0;
	
	ignition.redRange = 0.5;
	ignition.greenRange = 0.5;
	ignition.blueRange = 0.5;
	ignition.redSpeed = ignition.greenSpeed = ignition.blueSpeed = 1;
	ignition.color = ColRGBA(0.5,0.5,0.5,1);


	ignition.emitterCells = [NSArray arrayWithObject:explosionCell];
	
	multiplierIndicator = [CAGradientLayer layer];
	multiplierIndicator.frame = CGRectMake(0, 0, 128, [NSScreen mainScreen].frame.size.height);
	multiplierIndicator.colors = $array(ColRGBA2(0, 1, 0, .5), ColRGBA2(0, 1, 0, .5), ColRGBA2(0, 0, 0, 0), ColRGBA2(0, 0, 0, 0));
	multiplierIndicator.startPoint = CGPointMake(0, 0);
	multiplierIndicator.endPoint = CGPointMake(0, 1);
	multiplierIndicator.locations = $array([NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:1]);
	
	[self.layer addSublayer:multiplierIndicator];
	
	// If we want a sonar-style ping sound, enable this:
	//[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(proximitySound) userInfo:nil repeats:NO];
	
	

	
	return self;
}
-(void)cycleHighscoreColors;
{
	[CATransaction withAnimationSpeed:2.0 :^ {
		float alpha = 0.6;
		NSArray *newCols = $array(ColRGBA2(frandom()/2., frandom()/2., frandom()/2., alpha),
															ColRGBA2(frandom()/2., frandom()/2., frandom()/2., alpha),
															ColRGBA2(frandom()/2., frandom()/2., frandom()/2., alpha),
															ColRGBA2(frandom()/2., frandom()/2., frandom()/2., alpha));
		
		[CATransaction setCompletionBlock:^ {
			[self cycleHighscoreColors];
		}];
						
		highscoreLayer.colors = newCols;


	}];
}

-(void)clear;
{
	level = 0;
	self.score = 0;
	self.multiplier = 1;

	for (Orb *orb in self.orbs) 
		[orb removeFromSuperlayer];
	
	for (Square *square in self.squares)
		[square removeFromSuperlayer];
	
	[self.layer addSublayer:[Orb yellowOrb]];
}

-(void)playSound:(NSString*)name;
{
	NSSound *sound = [TCSound soundNamed:name];
	[sound play];
}

-(void)proximitySound;
{
	[self playSound:@"Proximity.wav"];
	
	Vector2 *mouse = [Vector2 vectorWithCGPoint:NSPointToCGPoint([NSEvent mouseLocation])];
	
	float minDistance = 1000;
	for(Orb *orb in self.orbs) {
		Vector2 *diff = [mouse vectorBySubtractingVector:orb.positionVector];
		minDistance = MIN([diff length], minDistance);
	}
	
	for(Square *square in self.squares) {
		Vector2 *diff = [mouse vectorBySubtractingVector:square.positionVector];
		minDistance = MIN([diff length], minDistance);
	}
	
	[NSTimer scheduledTimerWithTimeInterval:minDistance/1000. target:self selector:@selector(proximitySound) userInfo:nil repeats:NO];
}

-(void)levelUp;
{
	if(level != 0) {
		[self playSound:@"Levelup.wav"];
		[self blinkToColor:ColRGBA(0.5, 0.5, 1, 0.3)];
	}
	
	level++;
		
	for(int i = 0; i < level; i++) {
		Orb *foo = [Orb randomOrb];
	
		[self.layer addSublayer:foo];
	}
	if(level == 1 || level % 6 == 0)
		[self.layer addSublayer:[Square square]];
}

-(void)updateHighscores;
{
	dispatch_async(dispatch_get_global_queue(0, 0), ^ {
		NSError *error = nil;
		NSURL *url = [NSURL URLWithString:@"http://nevyn.nu/orbAvoidance/highscores.php?get"];
		NSString *highscoreString = [NSString stringWithContentsOfURL:url
																												 encoding:NSUTF8StringEncoding
																														error:&error];
		if(!highscoreString) {
			NSLog(@"Failed fetching highscores: %@", [error localizedDescription]);
			return;
		}
		
		NSArray *newScores = [[SBJsonParser new] objectWithString:highscoreString];
		
		if(!newScores) {
			NSLog(@"Failed to parse highscores: %@", highscoreString);
			return;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			self.highscores = newScores;
		
		});
	});
}

-(void)submitScore:(float)newScore;
{
	if(newScore < 10) return;
	
	dispatch_async(dispatch_get_global_queue(0, 0), ^ {
		NSError *error = nil;
		// Yes, I realize there is no security here whatsoever. Please don't ruin the party.
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://nevyn.nu/orbAvoidance/highscores.php?set&user=%@&score=%f", NSUserName(), newScore]];
		NSString *result = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
		if(!result) {
			NSLog(@"Failed uploading highscores: %@", [error localizedDescription]);
			return;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			if(self.highscores.count > 0 && newScore > [[[self.highscores lastObject] objectAtIndex:1] floatValue])
				[self updateHighscores];
		});
	});
}

-(NSArray*)orbs;
{
	return [[self.layer sublayers] filteredArray:^ BOOL (id obj) {
		return [obj class] == [Orb class];
	}];
}
-(NSArray*)squares;
{
	return [[self.layer sublayers] filteredArray:^ BOOL (id obj) {
		return [obj class] == [Square class];
	}];
}


-(void)gameover;
{
	[self playSound:@"Death.wav"];
	[self blinkToColor:ColRGBA(1, 0, 0, 0.3)];
	
	CAGradientLayer *grad = [CAGradientLayer layer];
	CGFloat w = [NSScreen mainScreen].frame.size.width, h = [NSScreen mainScreen].frame.size.height;
	grad.frame = CGRectMake(0.1*w, 0.9*h - 128, 0.8*w, 128);
	grad.colors = $array(ColRGBA2(1, 0, 0, 1), ColRGBA2(0, 1, 0, 1), ColRGBA2(0, 0, 1, 1), ColRGBA2(0, 0, 0, 0));
	grad.startPoint = CGPointMake(0, 0);
	grad.endPoint = CGPointMake(1, 0);
	grad.locations = $array([NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0]);
	TCAfter(0.01, ^ {
		[CATransaction withAnimationSpeed:4.0 : ^ {
			grad.locations = $array([NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0.4], [NSNumber numberWithFloat:0.8], [NSNumber numberWithFloat:1]);
			
		}];
	});
	
	CATextLayer * scorelayer = [CATextLayer layer];
	scorelayer.fontSize = 128;
	scorelayer.string = [NSString stringWithFormat:@"DEATH: %.0f pts", self.score];
	scorelayer.frame = CGRectMake(0, 0, grad.frame.size.width, grad.frame.size.height);
	scorelayer.shadowOpacity = 1.0;
	scorelayer.shadowRadius = 10.0;
	scorelayer.shadowOffset = CGSizeMake(10, -10);

	grad.mask = scorelayer;
	
	[self.layer addSublayer:grad];
	
	TCAfter(5.0, ^ {
		[grad removeFromSuperlayer];
	});
	
	[self submitScore:score];
	
	[self clear];	
	[self levelUp];
}

-(void)explodeAt:(CGPoint)p;
{
	[self playSound:@"Hit.wav"];
	
	CAEmitterLayer *explosion = [CAEmitterLayer layer];
	
	explosion.emitterPosition = p;
	explosion.renderMode = kCAEmitterLayerAdditive;
	explosion.emitterCells = [NSArray arrayWithObject:ignition];
	
	[self.layer addSublayer:explosion];	
	TCAfter(0.8, ^ {
		[explosion removeFromSuperlayer];
	});
}

-(void)blinkToColor:(CGColorRef)col;
{
	CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
	anim.fromValue = (id)col;
	anim.toValue = (id)fillLayer.backgroundColor;
	anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	anim.duration = 1.0;
	[fillLayer addAnimation:anim forKey:@"blink"];
}


-(void)update;
{
	[CATransaction withoutAnimations: ^{
		
		NSTimeInterval dt = [NSDate timeIntervalSinceReferenceDate] - lastUpdate;
		lastUpdate = [NSDate timeIntervalSinceReferenceDate];
		
		Vector2 *mouse = [Vector2 vectorWithCGPoint:NSPointToCGPoint([NSEvent mouseLocation])];
		
		for (Orb *orb in self.orbs) {
			Vector2 *m = [mouse vectorBySubtractingVector:orb.positionVector];
			float dist = [m length];
			Vector2 *newAcc = [m vectorByDividingWithScalar:dist];
			orb.acceleration = newAcc;
			
			[orb update:dt];
			
			if(dist < orb.frame.size.width/2.) {
				[self gameover];
				return;
			}
			
			
			if([orb orbSpeed] != 0)			
				for (Square *square in self.squares) {
					if( ! square.dangerous ) continue;

					Vector2 *cm = [square.positionVector vectorBySubtractingVector:orb.positionVector];
					float cubedist = [cm length];
					if(cubedist < square.frame.size.width/2.) {
						self.score += MIN(self.multiplier, kSuspenseMultiplier);
						self.multiplier += 1.;
						[self explodeAt:orb.position];
						[orb removeFromSuperlayer];
						break;
					}
				}
		}
	
		for (Square *square in self.squares) {
			if( ! square.dangerous ) continue;
			
			Vector2 *m = [mouse vectorBySubtractingVector:square.positionVector];
			float dist = [m length];
			if(dist < square.frame.size.width/2.) {
				[self gameover];
				return;
			}
		}
		
		if(self.orbs.count == 1)
			[self levelUp];
		
		self.multiplier = MAX(1, self.multiplier-dt);
		
		if( self.multiplier >= kSuspenseMultiplier && !suspense.isPlaying ) {
			[suspense play];
		} else if(self.multiplier < kSuspenseMultiplier && suspense.isPlaying ) {
			[suspense stop];
		}
		
		
	}];
}

@synthesize score, multiplier, highscores;
-(void)setMultiplier:(float)newMultiplier;
{
	static float lastBlur = 0;
	float diff = abs(lastBlur-newMultiplier);
	
	multiplier = newMultiplier;
	
	if(diff > 0.5) {
		if([((OrbWindow*)self.window) useBlur])
			[((OrbWindow*)self.window) setBlur:newMultiplier-1.];
		lastBlur = newMultiplier;
	}
	
	CGFloat frac = (newMultiplier - 1.)/(kSuspenseMultiplier-1.);
	[CATransaction withAnimations:^ {
		multiplierIndicator.locations = $array([NSNumber numberWithFloat:0], [NSNumber numberWithFloat:frac], [NSNumber numberWithFloat:frac+0.1], [NSNumber numberWithFloat:1]);
		
		[CATransaction withAnimationSpeed:1.0 :^ {
			if(newMultiplier > kSuspenseMultiplier)
				fillLayer.backgroundColor = ColRGBA(1, 1, 0, 0.2);
			else
				fillLayer.backgroundColor = ColRGBA(0, 0, 0, 0);
		}];
			
	}];
}

-(void)setHighscores:(NSArray *)newScores;
{
	highscores = newScores;
	
	[CATransaction withAnimationSpeed:2.0 :^ {
		__block int i = 0;
		highscoreNamesLayer.string  = [newScores foldInitialValue:@"" with:^(id soFar, id val) {
			return [soFar stringByAppendingFormat:@"%d %@\n", ++i, [val objectAtIndex:0]];
		}];
		highscoreScoresLayer.string = [newScores foldInitialValue:@"" with:^(id soFar, id val) {
			return [soFar stringByAppendingFormat:@"%d\n", [[val objectAtIndex:1] intValue]];
		}];
	}];
}
@end





@implementation Orb
+(Orb*)yellowOrb;
{
	return [[[Orb alloc] initWithColor:ColRGBA(1, 1, 0, 0.5) speed: 0] autorelease];
}
+(Orb*)redOrb; // slow
{
	return [[[Orb alloc] initWithColor:ColRGBA(1, 0, 0, 0.5) speed: 1] autorelease];
}
+(Orb*)purpleOrb; // medium
{
	return [[[Orb alloc] initWithColor:ColRGBA(1, 0, 1, 0.5) speed: 2] autorelease];
}
+(Orb*)blueOrb; // fast
{
	return [[[Orb alloc] initWithColor:ColRGBA(0.5, 0.5, 1, 0.5) speed: 3] autorelease];
}
+(Orb*)randomOrb;
{
	int i = random()%3;
	if(i == 0) return [self redOrb];
	if(i == 1) return [self purpleOrb];
	return [self blueOrb];
}
-(id)initWithColor:(CGColorRef)color_ speed:(CGFloat)speed_;
{
	if( ! [super init] ) return nil;
	
	self.backgroundColor = color_;
	self.frame = CGRectMake(random() % 2 ? 0 : [NSScreen mainScreen].frame.size.width, random() % (int)[NSScreen mainScreen].frame.size.height, speed_==0?15:10, speed_==0?15:10);
	self.cornerRadius = speed_==0?15/2.:10/2.;
	self.borderWidth = 1;
	
	orbSpeed = speed_;
	self.velocity = [Vector2 zero];
	self.acceleration = [Vector2 zero];
	
	const CGFloat *rgb = CGColorGetComponents(color_);
	self.borderColor = ColRGBA(rgb[0]*0.5, rgb[1]*0.5, rgb[2]*0.5, 1);
	
	return self;
}

-(void)update:(NSTimeInterval)dt;
{
	self.velocity = [self.velocity vectorByAddingVector:acceleration];
	self.velocity = [self.velocity vectorByMultiplyingWithScalar:0.87 + orbSpeed * 3 / 100.];
	self.positionVector = [self.positionVector vectorByAddingVector:velocity];

}

@synthesize orbSpeed;
@synthesize velocity, acceleration;

-(NSString*)description;
{
	return [NSString stringWithFormat:@"Speed %f orb", orbSpeed];
}

@end


@implementation Square
+(Square*)square;
{
	return [self layer];
}
-(id)init;
{
	if( ! [super init] ) return nil;
	
	self.backgroundColor = ColRGBA(0, 0, 0, 0.5);
	CGFloat w = [NSScreen mainScreen].frame.size.width, h = [NSScreen mainScreen].frame.size.height;
	
	self.frame = CGRectMake(w*0.1 + random() % (int)(w*0.8), h*0.1 + random() % (int)(h*0.8), 40, 40);
	self.cornerRadius = 6;
	//self.borderWidth = 1;
	//self.borderColor = ColRGBA(0, 0, 0, 0.8);
	self.dangerous = NO;
	
	CAAnimationGroup *agroup = [CAAnimationGroup animation];
	agroup.delegate = self;
	
	CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
	scale.fromValue = [NSNumber numberWithFloat:8.0];
	
	CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
	opacity.fromValue = [NSNumber numberWithFloat:0.0];
	
	CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	rotation.fromValue = [NSNumber numberWithFloat:M_PI];
	
	agroup.animations = $array(scale, opacity, rotation);
	agroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
	agroup.duration = 2.0;
	
	self.shadowOpacity = 1.0;
	self.shadowRadius = 10.0;
	self.shadowOffset = CGSizeMake(0, 0);

	
	[self addAnimation:agroup forKey:@"appearing"];
	
	return self;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag;
{
	self.dangerous = YES;
}

@synthesize dangerous;
@end


