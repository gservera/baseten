//
// PGTSAdditions.m
// BaseTen
//
// Copyright 2006-2010 Marko Karppinen & Co. LLC.
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
#import "PGTSAdditions.h"
#import "PGTSConnection.h"
#import "PGTSConstants.h"
#import "PGTSTypeDescription.h"
#import "PGTSConnectionPrivate.h"
#import "PGTSFoundationObjects.h"
#import "NSString+PGTSAdditions.h"
#import "BXLogger.h"


@implementation NSObject (PGTSAdditions)
- (NSString *) PGTSEscapedName: (PGTSConnection *) connection
{
	NSString* name = [[self description] escapeForPGTSConnection: connection];
	return [NSString stringWithFormat: @"\"%@\"", name];
}

- (NSString *) PGTSEscapedObjectParameter: (PGTSConnection *) connection
{
	NSString* retval = nil;
	size_t length = 0;
	const char* charParameter = [[self PGTSParameter: connection] PGTSParameterLength: &length connection: connection];
	if (charParameter)
	{
		PGconn* pgConn = [connection pgConnection];
		char* escapedParameter = (char *) calloc (1 + 2 * length, sizeof (char));
		PQescapeStringConn (pgConn, escapedParameter, charParameter, length, NULL);
		const char* clientEncoding = PQparameterStatus (pgConn, "client_encoding");
		BXAssertValueReturn (clientEncoding && 0 == strcmp ("UNICODE", clientEncoding), nil,
							 @"Expected client_encoding to be UNICODE (was: %s).", clientEncoding);
		retval = [[[NSString alloc] initWithBytesNoCopy: escapedParameter length: strlen (escapedParameter)
											   encoding: NSUTF8StringEncoding freeWhenDone: YES] autorelease];
	}
	return retval;
}
@end
