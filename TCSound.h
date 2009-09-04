//
//  TCSound.h
//  OrbAvoidance
//
//  Created by Joachim Bengtsson on 2009-09-03.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol NSSoundDelegate;


@interface TCSound : NSObject {
	id<NSObject, NSSoundDelegate> delegate;
	SystemSoundID  mySSID;
	BOOL loops;
	BOOL isPlaying;
}
+ (id)soundNamed:(NSString *)name;
- (id)initWithContentsOfURL:(NSURL *)url byReference:(BOOL)byRef;


- (BOOL)play;		/* sound is played asynchronously */
- (BOOL)pause;		/* returns NO if sound not paused */
- (BOOL)resume;		/* returns NO if sound not resumed */
- (BOOL)stop;
- (BOOL)isPlaying;


@property (assign) id<NSObject, NSSoundDelegate> delegate;
@property BOOL loops;
@end
