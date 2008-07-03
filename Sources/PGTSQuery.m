//
// PGTSQuery.m
// BaseTen
//
// Copyright (C) 2008 Marko Karppinen & Co. LLC.
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

#import "PGTSQuery.h"
#import "PGTSFoundationObjects.h"
#import "PGTSConnection.h"
#import "PGTSConnectionPrivate.h"
#import "PGTSProbes.h"
#import "PGTSHOM.h"


@implementation PGTSQuery
- (int) sendQuery: (PGTSConnection *) connection
{
	return 0;
}

- (NSString *) query
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}
@end


@implementation PGTSAbstractParameterQuery
- (NSArray *) parameters
{
	return mParameters;
}

- (void) setParameters: (NSArray *) anArray
{
	if (mParameters != anArray)
	{
		[mParameters release];
		mParameters = [anArray retain];
	}
}

- (int) parameterCount
{
	return [mParameters count];
}
@end


@implementation PGTSParameterQuery

- (NSString *) query
{
	return mQuery;
}

- (void) setQuery: (NSString *) aString
{
	if (mQuery != aString)
	{
		[mQuery release];
		mQuery = [aString copy];
	}
}

#if 0
static void
RemoveChars (char* str, const char* removed)
{
	BOOL copy = NO;
	while (1)
	{
		if ('\0' == *str)
			break;
		
		if (strchr (removed, *str))
		{
			copy = YES;
			break;
		}
		
		str++;
	}
	
	if (copy)
	{
		char* str2 = str;
		while (1)
		{
			*str = *str2;
			
			str2++;
			if (! strchr (removed, *str))
				str++;
			
			if ('\0' == *str)
				break;
		}
	}
}
#endif


static const char*
ParameterString (int nParams, const char** values, int* formats)
{
	NSMutableString* desc = [NSMutableString string];
	for (int i = 0; i < nParams; i++)
	{
		if (1 == formats [i])
			[desc appendString: @"<binary parameter>"];
		else
			[desc appendFormat: @"%s", values [i]];
		
		if (! (i == nParams - 1))
			[desc appendString: @", "];
	}
	return [desc UTF8String];
}


- (int) sendQuery: (PGTSConnection *) connection
{    
    int retval = 0;
	int nParams = [self parameterCount];
    const char** paramValues  = calloc (nParams, sizeof (char *));
    Oid*   paramTypes   = calloc (nParams, sizeof (Oid));
    int*   paramLengths = calloc (nParams, sizeof (int));
    int*   paramFormats = calloc (nParams, sizeof (int));

    for (int i = 0; i < nParams; i++)
    {
        id parameter = [mParameters objectAtIndex: i];
        int length = 0;
        const char* value = [parameter PGTSParameterLength: &length connection: connection];

        paramTypes   [i] = InvalidOid;
        paramValues  [i] = value;
        paramLengths [i] = length;
        paramFormats [i] = [parameter PGTSIsBinaryParameter];
    }

	//NSLog (@"sendquery: %@ %@", mQuery, mParameters);
	if (PGTS_SEND_QUERY_ENABLED ())
	{
		const char* params = ParameterString (nParams, paramValues, paramFormats);
		char* query_s = strdup ([mQuery UTF8String] ?: "");
		char* params_s = strdup (params ?: "");
		PGTS_SEND_QUERY (connection, retval, query_s, params_s);
		free (query_s);
		free (params_s);
	}
	
    retval = PQsendQueryParams ([connection pgConnection], [mQuery UTF8String], nParams, paramTypes,
                            	paramValues, paramLengths, paramFormats, 0);
	
    free (paramTypes);
    free (paramValues);
    free (paramLengths);
    free (paramFormats);

    return retval;
}

@end
