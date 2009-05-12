//
// PGTSDates.m
// BaseTen
//
// Copyright (C) 2008-2009 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://www.karppinen.fi/baseten/licensing/ or by contacting
// us at sales@karppinen.fi. Without an additional license, this software
// may be distributed only in compliance with the GNU General Public License.
//
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License, version 2.0,
// as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
// $Id$
//


#import <RegexKit/pcre.h>
#import "PGTSDates.h"
#import "PGTSConnection.h"
#import "PGTSTypeDescription.h"
#import "BXLogger.h"


#define kOvectorSize 64


struct regular_expression_st 
{
	pcre* re_expression;
	pcre_extra* re_extra;
	char* re_pattern;
};


static struct regular_expression_st gTimestampExp = {};
static struct regular_expression_st gDateExp = {};
static struct regular_expression_st gTimeExp = {};

__strong static NSDateComponents* gDefaultComponents = nil;


static void
SetDefaultComponents ()
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
		NSDate* date = [NSDate dateWithTimeIntervalSinceReferenceDate: 0.0];
		NSCalendar* calendar = [[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar] autorelease];
		NSUInteger units = (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | 
							NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit);
		NSDateComponents* components = [calendar components: units fromDate: date];
		gDefaultComponents = [components retain];
	}
}


static void
Compile (struct regular_expression_st* re, const char* pattern)
{
	const int options = PCRE_UTF8 | PCRE_MULTILINE | PCRE_DOLLAR_ENDONLY;
	const char* error = NULL;
	int errorOffset = 0;
	if ((re->re_expression = pcre_compile (pattern, options, &error, &errorOffset, NULL)))
	{
		re->re_extra = pcre_study (re->re_expression, 0, &error);
		if (error)
		{
			BXLogError (@"Failed to study pattern'%s': %s", pattern, error);
			pcre_free (re->re_expression);
		}
		else
		{
			re->re_pattern = strdup (pattern);
		}
	}
	else
	{
		BXLogError (@"Failed to compile pattern at offset %d '%s': %s", errorOffset, pattern, error);
	}
}


static NSDate*
MakeDate (struct regular_expression_st* re, const char* subject, int* ovector, int status)
{
	char buffer [16] = {};
	
	//Some reasonable default values.
	long year = 0;
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "y", buffer, 16))
		year = strtol (buffer, NULL, 10);
	else
		year = [gDefaultComponents year];
	
	long month = 0;
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "m", buffer, 16))
		month = strtol (buffer, NULL, 10);
	else
		month = [gDefaultComponents month];

	long day = 0;
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "d", buffer, 16))
		day = strtol (buffer, NULL, 10);
	else
		day = [gDefaultComponents day];

	long hours = 0;
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "H", buffer, 16))
		hours = strtol (buffer, NULL, 10);
	else
		hours = [gDefaultComponents hour];
	
	long minutes = 0;
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "M", buffer, 16))
		minutes = strtol (buffer, NULL, 10);
	else
		minutes = [gDefaultComponents minute];;
	
	long seconds = 0;
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "S", buffer, 16))
		seconds = strtol (buffer, NULL, 10);
	else
		seconds = [gDefaultComponents second];
	
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "e", buffer, 16))
		year *= -1;
	
	//Apparently this works as the Julian calendar when appropriate.
	//Not sure if Postgres does, though.
	NSCalendar* calendar = [[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar] autorelease];
	NSDateComponents* components = [[[NSDateComponents alloc] init] autorelease];
	[components setYear: year];
	[components setMonth: month];
	[components setDay: day];
	[components setHour: hours];
	[components setMinute: minutes];
	[components setSecond: seconds];
	
	{
		long tzOffset = 0;
		
		if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "tzh", buffer, 16))
			tzOffset += 3600 * strtol (buffer, NULL, 10);
		
		if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "tzm", buffer, 16))
			tzOffset += 60 * strtol (buffer, NULL, 10);
		
		if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "tzs", buffer, 16))
			tzOffset += strtol (buffer, NULL, 10);
		
		if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "tzd", buffer, 16))
		{
			if ('-' == buffer [0])
				tzOffset *= -1;
		}
		
		if (tzOffset)
		{
			NSTimeZone* tz = [NSTimeZone timeZoneForSecondsFromGMT: tzOffset];
			[calendar setTimeZone: tz];
		}
	}
	
	NSDate* retval = [calendar dateFromComponents: components];
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "frac", buffer, 16))
	{
		double fraction = strtol (buffer, NULL, 10);
		if (fraction)
		{
			double exp = log10 (fraction);
			exp = 1 + floor (exp);
			fraction /= pow (10, exp);
			[retval addTimeInterval: fraction];
		}
	}

	return retval;	
}


@implementation NSDate (PGTSFoundationObjects)
- (id) PGTSParameter: (PGTSConnection *) connection
{
	NSString* format = @"%Y-%m-%d %H:%M:%S";
	NSTimeZone* tz = [NSTimeZone timeZoneForSecondsFromGMT: 0];
	NSString* description = [self descriptionWithCalendarFormat: format timeZone: tz locale: nil];
    NSMutableString* retval = [NSMutableString stringWithString: description];
	
    double integralPart = 0.0;
    double subseconds = modf ([self timeIntervalSinceReferenceDate], &integralPart);    
    char* fractionalPart = NULL;
    asprintf (&fractionalPart, "%-.6f", fabs (subseconds));
    [retval appendFormat: @"%s+00:00:00", &fractionalPart [1]];
    free (fractionalPart);
    
    return retval;
}

+ (id) newForPGTSResultSet: (PGTSResultSet *) set withCharacters: (const char *) value type: (PGTSTypeDescription *) typeInfo
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}
@end


@implementation NSCalendarDate (PGTSFoundationObjects)
- (id) PGTSParameter: (PGTSConnection *) connection
{
	NSString* format = @"%Y-%m-%d %H:%M:%S";
	NSString* description = [self descriptionWithCalendarFormat: format];
    NSMutableString* retval = [NSMutableString stringWithString: description];
	
    double integralPart = 0.0;
    double subseconds = modf ([self timeIntervalSinceReferenceDate], &integralPart);
    char* fractionalPart = NULL;
    asprintf (&fractionalPart, "%-.6f", fabs (subseconds));
    [retval appendFormat: @"%s", &fractionalPart [1]];
    free (fractionalPart);
    
    NSInteger seconds = [[self timeZone] secondsFromGMT];
    [retval appendFormat: @"%+.2d:%.2d:%.2d", seconds / (60 * 60), (seconds % (60 * 60)) / 60, seconds % 60];
	return retval;
}
@end


@implementation PGTSDate
+ (void) initialize
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
		SetDefaultComponents ();

		//Date format is "yyyy-mm-dd". The year range is 4713 BC - 5874897 AD.
		//Years are zero-padded to at least four characters.
		//There might be a trailing 'BC' for years before 1 AD.

		const char* pattern = "^(?<y>\\d{4,7})-(?<m>\\d{2})-(?<d>\\d{2})(?<e> BC)?$";
		Compile (&gDateExp, pattern);
	}
}

+ (id) newForPGTSResultSet: (PGTSResultSet *) set withCharacters: (const char *) value type: (PGTSTypeDescription *) typeInfo
{
	NSDate* retval = nil;
	if (gDateExp.re_expression)
	{
		int ovector [kOvectorSize] = {};
		int status = pcre_exec (gDateExp.re_expression, gDateExp.re_extra, value, 
								strlen (value), 0, PCRE_ANCHORED, ovector, kOvectorSize);
		if (0 < status)
			retval = MakeDate (&gDateExp, value, ovector, status);
		else
			BXLogError (@"Unable to match timestamp string %s with pattern %s.", value, gTimestampExp.re_pattern);
	}
	return retval;
}
@end


@implementation PGTSTime
+ (void) initialize
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
		SetDefaultComponents ();
		
		//Time format is "hh:mm:ss". There is an optional subsecond part which can have
		//one to six digits. There is also an optional time zone part which has the format
		//"+01:20:02". The plus sign may be substituted with a minus. The minute and second
		//parts are both optional.
		
		const char* pattern = 
		"^(?<H>\\d{2}):(?<M>\\d{2}):(?<S>\\d{2})"                           //Time
		"(\\.(?<frac>\\d{1,6}))?"                                           //Fraction
		"((?<tzd>[+-])(?<tzh>\\d{2})(:(?<tzm>\\d{2})(:(?<tzs>\\d{2}))))?$"; //Time zone
		Compile (&gTimeExp, pattern);
	}
}

+ (id) newForPGTSResultSet: (PGTSResultSet *) set withCharacters: (const char *) value type: (PGTSTypeDescription *) typeInfo
{
	NSDate* retval = nil;
	if (gDateExp.re_expression)
	{
		int ovector [kOvectorSize] = {};
		int status = pcre_exec (gTimeExp.re_expression, gTimeExp.re_extra, value, 
								strlen (value), 0, PCRE_ANCHORED, ovector, kOvectorSize);
		if (0 < status)
			retval = MakeDate (&gTimeExp, value, ovector, status);
		else
			BXLogError (@"Unable to match time string %s with pattern %s.", value, gTimeExp.re_pattern);
	}
	return retval;
}
@end


@implementation PGTSTimestamp
+ (void) initialize
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
		SetDefaultComponents ();

		const char* pattern = 
		"^(?<y>\\d{4,7})-(?<m>\\d{2})-(?<d>\\d{2})"                       //Date
		" "
		"(?<H>\\d{2}):(?<M>\\d{2}):(?<S>\\d{2})"                          //Time
		"(\\.(?<frac>\\d{1,6}))?"                                         //Fraction
		"((?<tzd>[+-])(?<tzh>\\d{2})(:(?<tzm>\\d{2})(:(?<tzs>\\d{2}))))?" //Time zone
		"(?<e> BC)?$";                                                    //Era specifier
		Compile (&gTimestampExp, pattern);
	}
}

+ (id) newForPGTSResultSet: (PGTSResultSet *) set withCharacters: (const char *) value type: (PGTSTypeDescription *) typeInfo
{
	NSDate* retval = nil;
	if (gDateExp.re_expression)
	{
		int ovector [kOvectorSize] = {};
		int status = pcre_exec (gTimestampExp.re_expression, gTimestampExp.re_extra, value, 
								strlen (value), 0, PCRE_ANCHORED, ovector, kOvectorSize);
		if (0 < status)
			retval = MakeDate (&gTimestampExp, value, ovector, status);
		else
			BXLogError (@"Unable to match date string %s with pattern %s.", value, gTimestampExp.re_pattern);
	}
	return retval;
}
@end