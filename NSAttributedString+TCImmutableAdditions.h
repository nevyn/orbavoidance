//
//  NSAttributedString+TCImmutableAdditions.h
//  OrbAvoidance
//
//  Created by Joachim Bengtsson on 2009-09-05.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSAttributedString (TCImmutableAdditions)
+(NSAttributedString*)attributedString;
+(NSAttributedString*)attributedStringWithAttributes:(NSDictionary*)attributes forFormat:(NSString*)format, ... NS_FORMAT_FUNCTION(2, 3);
+(NSAttributedString*)attributedStringWithAttributes:(NSDictionary*)attributes forFormat:(NSString*)format arguments:(va_list)args;
+(NSAttributedString*)attributedStringWithFont:(NSFont*)font forFormat:(NSString*)format, ... NS_FORMAT_FUNCTION(2, 3);

-(NSAttributedString*)attributedStringByAppending:(NSAttributedString*)append;
@end
