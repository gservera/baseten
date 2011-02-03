//
// BXPGSQLScanner.m
// BaseTen
//
// Copyright 2008 Marko Karppinen & Co. LLC.
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
#import <stdint.h>

typedef uint64_t uint64;

#import <stdbool.h> //Should bool be char instead?
#import "psqlscan.h"
#import "settings.h"
#import "pqexpbuffer.h"

PsqlSettings pset = {};

void UnsyncVariables ()
{
	//Do nothing.
}


#import "BXPGSQLScanner.h"

static NSString* 
QueryFromBuffer (PQExpBuffer buffer)
{
	char* query = buffer->data;
	size_t length = buffer->len;
	NSString* retval = [[[NSString alloc] initWithBytes: query length: length encoding: NSUTF8StringEncoding] autorelease];
	resetPQExpBuffer (buffer);
	return retval;
}


@implementation BXPGSQLScanner

- (id) init
{
	if ((self = [super init]))
	{
		mQueryBuffer = createPQExpBuffer ();
		mScanState = psql_scan_create ();
		mShouldStartScanning = YES;
	}
	return self;
}

- (void) dealloc
{
	destroyPQExpBuffer (mQueryBuffer);
	psql_scan_destroy (mScanState);
	[super dealloc];
}

- (void) finalize
{
	destroyPQExpBuffer (mQueryBuffer);
	psql_scan_destroy (mScanState);
	[super finalize];
}

- (void) setDelegate: (id <BXPGSQLScannerDelegate>) anObject
{
	mDelegate = anObject;
}

- (void) continueScanning
{
	if (! mCurrentLine)
		mCurrentLine = [mDelegate nextLineForScanner: self];
		
	if (mCurrentLine)
	{
		if (mShouldStartScanning)
		{
			psql_scan_setup (mScanState, mCurrentLine, strlen (mCurrentLine));
			mShouldStartScanning = NO;
		}
		
		promptStatus_t promptStatus = PROMPT_READY; //Quite the same what we have here; it's write-only.
		PsqlScanResult scanResult = psql_scan (mScanState, mQueryBuffer, &promptStatus);
		
		switch (scanResult)
		{
			/* found command-ending semicolon */
			case PSCAN_SEMICOLON:
			{
				NSString* query = QueryFromBuffer (mQueryBuffer);
				[mDelegate scanner: self scannedQuery: query complete: YES];
				break;
			}
			
			/* end of line, SQL possibly complete */
			case PSCAN_EOL:
			/* end of line, SQL statement incomplete */
			case PSCAN_INCOMPLETE:
			{
				psql_scan_finish (mScanState);
				mCurrentLine = NULL;
				const char* nextLine = [mDelegate nextLineForScanner: self];
				if (nextLine)
				{
					mCurrentLine = nextLine;
					mShouldStartScanning = YES;
					[self continueScanning];
					//Tail recursion.
				}
				else
				{
					NSString* query = QueryFromBuffer (mQueryBuffer);
					psql_scan_finish (mScanState);
					mCurrentLine = NULL;
					mShouldStartScanning = YES;
					[mDelegate scanner: self scannedQuery: query complete: NO];
				}				
				break;
			}				
				
			/* found backslash command */
			case PSCAN_BACKSLASH:
			{
				NSString* commandString = nil;
				NSString* optionsString = nil;
				
				char* command = psql_scan_slash_command (mScanState);
				commandString = [[[NSString alloc] initWithBytesNoCopy: command length: strlen (command)
															 encoding: NSUTF8StringEncoding freeWhenDone: YES]
								 autorelease];
				
				char* options = psql_scan_slash_option (mScanState, OT_WHOLE_LINE, NULL, true);
				if (options)
				{
					//Options has a trailing newline.
					optionsString = [[[NSString alloc] initWithBytesNoCopy: options length: strlen (options) - 1
																  encoding: NSUTF8StringEncoding freeWhenDone: YES]
									 autorelease];
				}
				
				psql_scan_slash_command_end (mScanState);
				psql_scan_finish (mScanState);
				mCurrentLine = NULL;
				mShouldStartScanning = YES;

				[mDelegate scanner: self scannedCommand: commandString options: optionsString];
				break;
			}
		}
	}
}

@end
