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
#import "TCSound.h"

#define ColRGBA(R, G, B, A) (CGColorRef)CFMakeCollectable(CGColorCreateGenericRGB(R, G, B, A))

@implementation OrbView

+(void)initialize;
{
	srandom(time(NULL));
}

- (id)initWithFrame:(NSRect)frame {
	if( ! [super initWithFrame:frame] ) return nil;
	
	self.wantsLayer = YES;
	
	[self clear];	
	[self levelUp];
	
	timer = [NSTimer scheduledTimerWithTimeInterval:1./60. target:self selector:@selector(update) userInfo:nil repeats:YES];
	
	lastUpdate = [NSDate timeIntervalSinceReferenceDate];
	
	
	
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
	//explosionCell.yAcceleration = -80;
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
	multiplierIndicator.colors = [NSArray arrayWithObjects:(id)ColRGBA(0, 1, 0, .5), ColRGBA(0, 1, 0, .5), ColRGBA(0, 0, 0, 0), ColRGBA(0, 0, 0, 0), nil];
	multiplierIndicator.startPoint = CGPointMake(0, 0);
	multiplierIndicator.endPoint = CGPointMake(0, 1);
	multiplierIndicator.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:1], nil];
	
	[self.layer addSublayer:multiplierIndicator];
	
	return self;
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
	NSSound *sound = [[TCSound soundNamed:name] retain];
	sound.delegate = self;
	[sound play];
}
-(void)sound:(NSSound*)sound_ didFinishPlaying:(BOOL)yes;
{
	[sound_ release];
}

-(void)levelUp;
{
	level++;
		
	for(int i = 0; i < level; i++) {
		Orb *foo = [Orb randomOrb];
	
		[self.layer addSublayer:foo];
	}
	if(level == 1 || level % 6 == 0)
		[self.layer addSublayer:[Square square]];
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
	
	CAGradientLayer *grad = [CAGradientLayer layer];
	CGFloat w = [NSScreen mainScreen].frame.size.width, h = [NSScreen mainScreen].frame.size.height;
	grad.frame = CGRectMake(0.1*w, 0.9*h - 128, 0.8*w, 128);
	grad.colors = [NSArray arrayWithObjects:(id)ColRGBA(1, 0, 0, 1), ColRGBA(0, 1, 0, 1), ColRGBA(0, 0, 1, 1), ColRGBA(0, 0, 0, 0), nil];
	grad.startPoint = CGPointMake(0, 0);
	grad.endPoint = CGPointMake(1, 0);
	grad.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0], nil];
	TCAfter(0.01, ^ {
		[CATransaction withAnimationSpeed:4.0 : ^ {
			grad.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0.4], [NSNumber numberWithFloat:0.8], [NSNumber numberWithFloat:1], nil];
			
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
						self.score += MIN(self.multiplier, 10.);
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
		
		
		
	}];
}

@synthesize score, multiplier;
-(void)setMultiplier:(float)newMultiplier;
{
	static float lastBlur = 0;
	float diff = abs(lastBlur-newMultiplier);
	
	multiplier = newMultiplier;
	
	if(diff > 0.5) {
		[((OrbWindow*)self.window) setBlur:newMultiplier-1.];
		lastBlur = newMultiplier;
	}
	
	CGFloat frac = (newMultiplier - 1.)/9.;
	[CATransaction withAnimations:^ {
		multiplierIndicator.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:frac], [NSNumber numberWithFloat:frac+0.1], [NSNumber numberWithFloat:1], nil];
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
	
	agroup.animations = [NSArray arrayWithObjects:scale, opacity, rotation, nil];
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


