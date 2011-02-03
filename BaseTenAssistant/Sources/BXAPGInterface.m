//
// BXAPGInterface.m
// BaseTen Assistant
//
// Copyright 2008-2009 Marko Karppinen & Co. LLC.
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

#import "BXAPGInterface.h"
#import "BXAController.h"
#import <BaseTen/PGTSQuery.h>


#ifdef BXA_ENABLE_TRACE
static void
LogSocketCallback (CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info)
{
	NSString* logString = [[NSString alloc] initWithData: (NSData *) data encoding: NSUTF8StringEncoding];
	[(id) info logAppend: logString];
}
#endif



@implementation BXAPGInterface

@synthesize controller = mController;


#ifdef BXA_ENABLE_TRACE
- (FILE *) traceFile
{
	return NULL;
}


//FIXME: move this inside a method.
{
	int socketVector [2] = {};
	socketpair (AF_UNIX, SOCK_STREAM, 0, socketVector);
	CFSocketContext ctx = {0, mController, NULL, NULL, NULL};
	
	mTraceInput = fdopen (socketVector [0], "w");		
	mTraceOutput = CFSocketCreateWithNative (NULL, socketVector [1], kCFSocketDataCallBack, &LogSocketCallback, &ctx);
	mTraceSource = CFSocketCreateRunLoopSource (NULL, mTraceOutput, -1);
	CFRunLoopAddSource (CFRunLoopGetCurrent (), mTraceSource, kCFRunLoopCommonModes);
	
	[(BXPGInterface *) [mContext databaseInterface] setTraceFile: mTraceInput];
}
#endif


- (void) connection: (PGTSConnection *) connection sentQueryString: (const char *) queryString
{
	[mController logAppend: [NSString stringWithCString: queryString encoding: NSUTF8StringEncoding]];
	[mController logAppend: @"\n"];
}

- (void) connection: (PGTSConnection *) connection sentQuery: (PGTSQuery *) query
{
	[mController logAppend: [query query]];
	[mController logAppend: @"\n"];
}

- (void) connection: (PGTSConnection *) connection receivedResultSet: (PGTSResultSet *) res
{
}

- (BOOL) logsQueries
{
	return YES;
}
@end
