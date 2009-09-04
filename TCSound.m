//
//  TCSound.m
//  OrbAvoidance
//
//  Created by Joachim Bengtsson on 2009-09-03.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import "TCSound.h"

static void MyCompletionCallback (
    SystemSoundID  ssid,
    TCSound *sound
) {
	[sound stop];
	if(sound.loops)
		[sound play];
	else
		[sound.delegate sound:(NSSound*)sound didFinishPlaying:YES];
}


@implementation TCSound
@synthesize delegate, loops;
+ (id)soundNamed:(NSString *)name;
{
	NSURL *path = [[NSBundle mainBundle] URLForResource:name withExtension:nil];
	if(!path) return nil;
	return [[[TCSound alloc] initWithContentsOfURL:path byReference:YES] autorelease];
}

- (id)initWithContentsOfURL:(NSURL *)url byReference:(BOOL)byRef;
{
	if( ! [super init] ) return nil;
	
	OSStatus error = AudioServicesCreateSystemSoundID((CFURLRef)url, &mySSID);
	
	if(error != noErr)
		return nil;
	
	
	return self;
}

-(void)dealloc;
{
	AudioServicesDisposeSystemSoundID(mySSID);
	[super dealloc];
}
-(void)finalize;
{
	AudioServicesDisposeSystemSoundID(mySSID);
	[super finalize];
}

- (BOOL)play;
{
	CFRetain(self);
	AudioServicesAddSystemSoundCompletion (
        mySSID,
        NULL,
        NULL,
        (AudioServicesSystemSoundCompletionProc)MyCompletionCallback,
        (void *) self
    );

	AudioServicesPlaySystemSound (mySSID);
	isPlaying = YES;
	return YES;
}
- (BOOL)stop;
{
	CFRelease(self);
	AudioServicesRemoveSystemSoundCompletion(mySSID);
	isPlaying = NO;
	return YES;
}

- (BOOL)pause;
{
	return NO;
}
- (BOOL)resume;
{
	return NO;
}
- (BOOL)isPlaying;
{
	return isPlaying;
}



@end
