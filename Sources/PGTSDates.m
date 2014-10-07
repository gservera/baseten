//
// PGTSDates.m
// BaseTen
//
// Copyright 2008-2010 Marko Karppinen & Co. LLC.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//


#import "PGTSDates.h"
#import "PGTSConnection.h"
#import "PGTSTypeDescription.h"
#import "BXLogger.h"
#import "BXArraySize.h"
#import "BXRegularExpressions.h"


#define kOvectorSize 64


static struct bx_regular_expression_st gTimestampExp = {};
static struct bx_regular_expression_st gDateExp = {};
static struct bx_regular_expression_st gTimeExp = {};

__strong static NSDateComponents* gDefaultComponents = nil;
__strong static NSTimeZone* gDefaultTimeZone = nil;
__strong static NSCalendar* __gregorianCalendar;


static void
SetDefaults ()
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
		
		gDefaultTimeZone = [[NSTimeZone timeZoneWithName: @"UTC"] retain];
		
		NSDate* date = [NSDate dateWithTimeIntervalSinceReferenceDate: 0.0];
		NSCalendar* calendar = [[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar] autorelease];
		[calendar setTimeZone: gDefaultTimeZone];
		
		NSUInteger units = (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | 
							NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit);
		NSDateComponents* components = [calendar components: units fromDate: date];
		gDefaultComponents = [components retain];
	}
}


static NSDate*
CopyDate (struct bx_regular_expression_st *re, const char *subject, int *ovector, int status)
{
	NSDate* retval = nil;
	char buffer [16] = {};
	
	//Some reasonable default values.
	long year = 0;
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "y", buffer, BXArraySize (buffer)))
		year = strtol (buffer, NULL, 10);
	else
		year = [gDefaultComponents year];
	
	long month = 0;
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "m", buffer, BXArraySize (buffer)))
		month = strtol (buffer, NULL, 10);
	else
		month = [gDefaultComponents month];
	
	long day = 0;
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "d", buffer, BXArraySize (buffer)))
		day = strtol (buffer, NULL, 10);
	else
		day = [gDefaultComponents day];
	
	long hours = 0;
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "H", buffer, BXArraySize (buffer)))
		hours = strtol (buffer, NULL, 10);
	else
		hours = [gDefaultComponents hour];
	
	long minutes = 0;
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "M", buffer, BXArraySize (buffer)))
		minutes = strtol (buffer, NULL, 10);
	else
		minutes = [gDefaultComponents minute];;
	
	long seconds = 0;
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "S", buffer, BXArraySize (buffer)))
		seconds = strtol (buffer, NULL, 10);
	else
		seconds = [gDefaultComponents second];
	
	//ICU's unicode/gregocal.h: BC == 0, AD == 1.
	long era = 1;
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "e", buffer, BXArraySize (buffer)))
		era = 0;
	
	//NSGregorianCalendar works as the Julian calendar when appropriate.
	//Not sure if Postgres does, though. Time zone needs to be set always, because
	//NSCalendar defaults to the current time zone.
    if (!__gregorianCalendar) {
        __gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    }
    
	long tzOffset = 0;
	
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "tzh", buffer, BXArraySize (buffer)))
		tzOffset += 3600 * strtol (buffer, NULL, 10);
	
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "tzm", buffer, BXArraySize (buffer)))
		tzOffset += 60 * strtol (buffer, NULL, 10);
	
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "tzs", buffer, BXArraySize (buffer)))
		tzOffset += strtol (buffer, NULL, 10);
	
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "tzd", buffer, BXArraySize (buffer)))
	{
		if ('-' == buffer [0])
			tzOffset *= -1;
	}
	
	NSTimeZone* tz = gDefaultTimeZone;
	if (tzOffset)
		tz = [NSTimeZone timeZoneForSecondsFromGMT: tzOffset];
	[__gregorianCalendar setTimeZone: tz];
	
	NSDateComponents* components = [[[NSDateComponents alloc] init] autorelease];
	[components setEra: era];
	[components setYear: year];
	[components setMonth: month];
	[components setDay: day];
	[components setHour: hours];
	[components setMinute: minutes];
	[components setSecond: seconds];
	
	retval = [__gregorianCalendar dateFromComponents: components];
	if (0 < pcre_copy_named_substring (re->re_expression, subject, ovector, status, "frac", buffer, BXArraySize (buffer)))
	{
		double fraction = strtod (buffer, NULL);
		if (fraction)
			retval = [retval dateByAddingTimeInterval: fraction];
	}
	
	return [retval retain];
}


@implementation NSDate (PGTSFoundationObjects)
- (id) PGTSParameter: (PGTSConnection *) connection
{
	NSString* retval = nil;
	NSUInteger units = (NSEraCalendarUnit | 
						NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit |
						NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit);
	NSCalendar* calendar = [[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar] autorelease];
	[calendar setTimeZone: gDefaultTimeZone];
	
	NSDateComponents* comps = [calendar components: units fromDate: self];
	
	char buffer [9] = {}; //0.123456 + nul character
	char* fraction = buffer;
    double integralPart = 0.0;
    double subseconds = modf ([self timeIntervalSinceReferenceDate], &integralPart);
	Expect (0.0 <= subseconds);
	if (subseconds)
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat"
		Expect (0 < snprintf(fraction, (sizeof(buffer)/sizeof(*buffer)), "%-.6f", subseconds));
#pragma clang diagnostic pop
		fraction++;
	}
	
	NSString* format = @"%04d-%02d-%02d %02d:%02d:%02d%s+00%s";
	retval = [NSString stringWithFormat: format,
			  [comps year], [comps month], [comps day], 
			  [comps hour], [comps minute], [comps second],
			  fraction,
			  ([comps era] ? "" : " BC")];
	
	return retval;
}

+ (id) copyForPGTSResultSet: (PGTSResultSet *) set withCharacters: (const char *) value type: (PGTSTypeDescription *) typeInfo
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}
@end


@implementation PGTSDate
+ (void) initialize
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
		SetDefaults ();
		
		//Date format is "yyyy-mm-dd". The year range is 4713 BC - 5874897 AD.
		//Years are zero-padded to at least four characters.
		//There might be a trailing 'BC' for years before 1 AD.
		
		const char* pattern = "^(?<y>\\d{4,7})-(?<m>\\d{2})-(?<d>\\d{2})(?<e> BC)?$";
		BXRECompile (&gDateExp, pattern);
	}
}

+ (id) copyForPGTSResultSet: (PGTSResultSet *) set withCharacters: (const char *) value type: (PGTSTypeDescription *) typeInfo
{
	Expect (gDateExp.re_expression);
	
	NSDate* retval = nil;
	int ovector [kOvectorSize] = {};
	int status = pcre_exec (gDateExp.re_expression, gDateExp.re_extra, value, 
							strlen (value), 0, PCRE_ANCHORED, ovector, kOvectorSize);
	if (0 < status)
		retval = CopyDate (&gDateExp, value, ovector, status);
	else
		BXLogError (@"Unable to match timestamp string %s with pattern %s.", value, gTimestampExp.re_pattern);
	
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
		SetDefaults ();
		
		//Time format is "hh:mm:ss". There is an optional subsecond part which can have
		//one to six digits. There is also an optional time zone part which has the format
		//"+01:20:02". The plus sign may be substituted with a minus. The minute and second
		//parts are both optional.
		
		const char* pattern = 
		"^(?<H>\\d{2}):(?<M>\\d{2}):(?<S>\\d{2})"                             //Time
		"(?<frac>\\.\\d{1,6})?"                                               //Fraction
		"((?<tzd>[+-])(?<tzh>\\d{2})(:(?<tzm>\\d{2})(:(?<tzs>\\d{2}))?)?)?$"; //Time zone
		BXRECompile (&gTimeExp, pattern);
	}
}

+ (id) copyForPGTSResultSet: (PGTSResultSet *) set withCharacters: (const char *) value type: (PGTSTypeDescription *) typeInfo
{
	Expect (gTimeExp.re_expression)
	
	NSDate* retval = nil;
	int ovector [kOvectorSize] = {};
	int status = pcre_exec (gTimeExp.re_expression, gTimeExp.re_extra, value, 
							strlen (value), 0, PCRE_ANCHORED, ovector, kOvectorSize);
	if (0 < status)
		retval = CopyDate (&gTimeExp, value, ovector, status);
	else
		BXLogError (@"Unable to match time string %s with pattern %s.", value, gTimeExp.re_pattern);
	
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
		SetDefaults ();
		
		const char* pattern = 
		"^(?<y>\\d{4,7})-(?<m>\\d{2})-(?<d>\\d{2})"                         //Date
		" "
		"(?<H>\\d{2}):(?<M>\\d{2}):(?<S>\\d{2})"                            //Time
		"(?<frac>\\.\\d{1,6})?"                                             //Fraction
		"((?<tzd>[+-])(?<tzh>\\d{2})(:(?<tzm>\\d{2})(:(?<tzs>\\d{2}))?)?)?" //Time zone
		"(?<e> BC)?$";                                                      //Era specifier
		BXRECompile (&gTimestampExp, pattern);
	}
}

+ (id) copyForPGTSResultSet: (PGTSResultSet *) set withCharacters: (const char *) value type: (PGTSTypeDescription *) typeInfo
{
	Expect (gTimestampExp.re_expression);
	
	NSDate* retval = nil;
	int ovector [kOvectorSize] = {};
	int status = pcre_exec (gTimestampExp.re_expression, gTimestampExp.re_extra, value, 
							strlen (value), 0, PCRE_ANCHORED, ovector, kOvectorSize);
	if (0 < status)
		retval = CopyDate (&gTimestampExp, value, ovector, status);
	else
		BXLogError (@"Unable to match date string %s with pattern %s.", value, gTimestampExp.re_pattern);
	
	return retval;
}
@end
