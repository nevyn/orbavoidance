//
//  NSAttributedString+TCImmutableAdditions.m
//  OrbAvoidance
//
//  Created by Joachim Bengtsson on 2009-09-05.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import "NSAttributedString+TCImmutableAdditions.h"


@implementation NSAttributedString (TCImmutableAdditions)
+(NSAttributedString*)attributedString;
{
	return [[[[self class] alloc] initWithString:@""] autorelease];
}
+(NSAttributedString*)attributedStringWithAttributes:(NSDictionary*)attributes forFormat:(NSString*)format, ...;
{
	va_list valist;
	va_start(valist, format);
	NSAttributedString *nsas = [NSAttributedString attributedStringWithAttributes:attributes forFormat:format arguments:valist];
	va_end(valist);
	return nsas;

}
+(NSAttributedString*)attributedStringWithAttributes:(NSDictionary*)attributes forFormat:(NSString*)format arguments:(va_list)args;
{
		return [[[NSAttributedString alloc] initWithString:[[[NSString alloc] initWithFormat:format arguments:args] autorelease] attributes:attributes] autorelease];
}
+(NSAttributedString*)attributedStringWithFont:(NSFont*)font forFormat:(NSString*)format, ...
{
	NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
	va_list valist;
	va_start(valist, format);
	NSAttributedString *nsas = [NSAttributedString attributedStringWithAttributes:attributes forFormat:format arguments:valist];
	va_end(valist);
	return nsas;
}

-(NSAttributedString*)attributedStringByAppending:(NSAttributedString*)append;
{
	NSMutableAttributedString *str = [[[NSMutableAttributedString alloc] initWithAttributedString:self] autorelease];
	[str appendAttributedString:append];
	return str;
}
@end
