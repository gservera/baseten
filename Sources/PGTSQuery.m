//
// PGTSQuery.m
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

#import "PGTSQuery.h"
#import "PGTSFoundationObjects.h"
#import "PGTSConnection.h"
#import "PGTSConnectionPrivate.h"
#import "PGTSProbes.h"
#import "BXHOM.h"
#import "BXLogger.h"
#import "BXSocketDescriptor.h"


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


- (id) visitQuery: (id <PGTSQueryVisitor>) visitor
{
	return [visitor visitQuery: self];
}
@end



@implementation PGTSAbstractParameterQuery
- (void) dealloc
{
	[mParameters release];
	[super dealloc];
}


- (NSArray *) parameters
{
	NSArray *retval = nil;
	@synchronized (self)
	{
		retval = [[mParameters copy] autorelease];
	}
	return retval;
}


- (void) setParameters: (NSArray *) anArray
{
	@synchronized (self)
	{
		if (mParameters != anArray)
		{
			[mParameters release];
			mParameters = [anArray copy];
		}
	}
}


- (NSUInteger) parameterCount
{
	NSUInteger retval = 0;
	@synchronized (self)
	{
		retval = [mParameters count];
	}
	return retval;
}


- (id) visitQuery: (id <PGTSQueryVisitor>) visitor
{
	return [visitor visitParameterQuery: self];
}
@end



@implementation PGTSParameterQuery
- (void) dealloc
{
	[mQuery release];
	[super dealloc];
}


- (NSString *) query
{
	NSString *retval = nil;
	@synchronized (self)
	{
		retval = [[mQuery retain] autorelease];
	}
	return retval;
}


- (void) setQuery: (NSString *) aString
{
	@synchronized (self)
	{
		if (mQuery != aString)
		{
			[mQuery release];
			mQuery = [aString copy];
		}
	}
}


#if 0
static void
RemoveChars (char *str, char const *removed)
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


static char*
CopyParameterString (int nParams, char const * const * const values, int const * const formats)
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
	char *retval = strdup ([desc UTF8String] ?: "");
	
	//For GC.
	[desc self];
	return retval;
}


- (int) sendQuery: (PGTSConnection *) connection
{
    int retval = 0;
	//For some reason, libpq doesn't receive signal or EPIPE from send if network is down. Hence we check it here.
	if ([connection canSend])
	{
		ExpectR ([[connection socketDescriptor] isLocked], retval);
		@synchronized (self)
		{
			NSUInteger nParams = [self parameterCount];
			NSArray* parameterObjects = [[mParameters BX_Collect] PGTSParameter: connection];
			
			char const **paramValues = calloc (nParams, sizeof (char *));
			Oid *paramTypes   = calloc (nParams, sizeof (Oid));
			int *paramLengths = calloc (nParams, sizeof (int));
			int *paramFormats = calloc (nParams, sizeof (int));
			
			for (int i = 0; i < nParams; i++)
			{
				BOOL isBinary = [[mParameters objectAtIndex: i] PGTSIsBinaryParameter];
				id parameter = [parameterObjects objectAtIndex: i];
				size_t length = 0;
				const char* value = [parameter PGTSParameterLength: &length connection: connection];
				
				paramTypes   [i] = InvalidOid;
				paramValues  [i] = value;
				paramLengths [i] = (isBinary ? (int)length : 0);
				paramFormats [i] = isBinary;
			}
			
			if (BASETEN_POSTGRESQL_SEND_QUERY_ENABLED ())
			{
				char *params = CopyParameterString ((int)nParams, paramValues, paramFormats);
				char *query = strdup ([mQuery UTF8String] ?: "");
				BASETEN_POSTGRESQL_SEND_QUERY (connection, retval, query, params);
				free (query);
				free (params);
			}
			
			if (nParams)
			{
				retval = PQsendQueryParams ([connection pgConnection], [mQuery UTF8String], (int)nParams, paramTypes,
											paramValues, paramLengths, paramFormats, 0);
			}
			else
			{
				retval = PQsendQuery ([connection pgConnection], [mQuery UTF8String]);
			}
			
			free (paramTypes);
			free (paramValues);
			free (paramLengths);
			free (paramFormats);
			
			//For GC.
			[parameterObjects self];
		}
		
		[connection logQueryIfNeeded: self];
	}
    return retval;
}
@end
