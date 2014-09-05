//
// NSString+PGTSAdditions.m
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

#import <stdlib.h>
#import <limits.h>
#import <BaseTen/libpq-fe.h>
#import "NSString+PGTSAdditions.h"
#import "PGTSConnection.h"


char *
PGTSCopyEscapedString (PGTSConnection *conn, const char *from)
{
	size_t length = strlen (from);
    char* to = (char *) calloc (1 + 2 * length, sizeof (char));
    PQescapeStringConn ([conn pgConnection], to, from, length, NULL);
	return to;
}


NSString* 
PGTSReformatErrorMessage (NSString* message)
{
	NSMutableString* result = [NSMutableString string];
	NSCharacterSet* skipSet = [NSCharacterSet characterSetWithCharactersInString: @"\t"];
	NSCharacterSet* newlineSet = [NSCharacterSet characterSetWithCharactersInString: @"\n"];
	NSInteger i = 0;
	NSScanner* scanner = [NSScanner scannerWithString: message];
	[scanner setCharactersToBeSkipped: skipSet];
	
	while (1)
	{
		NSString* part = nil;
		if ([scanner scanUpToCharactersFromSet: newlineSet intoString: &part])
		{
			[scanner scanCharactersFromSet: newlineSet intoString: NULL];
			[result appendString: part];
			if (! i)
				[result appendString: @"."];
			
			i++;
		}
		
		if ([scanner isAtEnd])
			break;
		else
			[result appendString: @" "];
	}
	
	if (0 < [result length])
	{
		NSString* begin = [result substringToIndex: 1];
		begin = [begin uppercaseString];
		[result replaceCharactersInRange: NSMakeRange (0, 1) withString: begin];
	}
	
	return [[result copy] autorelease];
}


@implementation NSString (PGTSAdditions)
/**
 * \internal
 * \brief Escape the string for the SQL interpreter.
 */
- (NSString *) escapeForPGTSConnection: (PGTSConnection *) connection
{
    const char *from = [self UTF8String];
	char *to = PGTSCopyEscapedString (connection, from);
    NSString* retval = [NSString stringWithUTF8String: to];
    free (to);
    return retval;
}

- (NSString *) quotedIdentifierForPGTSConnection: (PGTSConnection *) connection
{
	return [NSString stringWithFormat: @"\"%@\"", [self escapeForPGTSConnection: connection]];
}
@end
