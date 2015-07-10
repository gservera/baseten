//
// PGTSSynchronousConnector.m
// BaseTen
//
// Copyright 2010 Marko Karppinen & Co. LLC.
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

#import "PGTSSynchronousConnector.h"
#import "BXLogger.h"


@implementation PGTSSynchronousConnector
- (BOOL) connect: (NSDictionary *) connectionDictionary
{
	//Here libpq can resolve the name for us, because we don't use CFRunLoop and CFSocket.

    BOOL retval = NO;
	[self prepareToConnect];
	char* conninfo = PGTSCopyConnectionString (connectionDictionary);
	if ([self start: conninfo] && CONNECTION_BAD != PQstatus (mConnection))
	{
		mNegotiationStarted = YES;
		fd_set mask = {};
		struct timeval timeout = {.tv_sec = 15, .tv_usec = 0};
		PostgresPollingStatusType pollingStatus = PGRES_POLLING_WRITING; //Start with this
		int selectStatus = 0;
		int bsdSocket = PQsocket (mConnection);
		BOOL stop = NO;
		
		if (mTraceFile)
			PQtrace (mConnection, mTraceFile);
		
		if (bsdSocket < 0)
			BXLogInfo (@"Unable to get connection socket from libpq.");
		else
		{
			//Polling loop
			while (1)
			{
				struct timeval ltimeout = timeout;
				FD_ZERO (&mask);
				FD_SET (bsdSocket, &mask);
				selectStatus = 0;
				pollingStatus = mPollFunction (mConnection);
				
				BXLogDebug (@"Polling status: %d connection status: %d", pollingStatus, PQstatus (mConnection));
				
				[self setUpSSL];
				
				switch (pollingStatus)
				{
					case PGRES_POLLING_OK:
						retval = YES;
						//Fall through.
					case PGRES_POLLING_FAILED:
						stop = YES;
						break;
						
					case PGRES_POLLING_ACTIVE:
						//Select returns 0 on timeout
						selectStatus = 1;
						break;
						
					case PGRES_POLLING_READING:
						selectStatus = select (bsdSocket + 1, &mask, NULL, NULL, &ltimeout);
						break;
						
					case PGRES_POLLING_WRITING:
					default:
						selectStatus = select (bsdSocket + 1, NULL, &mask, NULL, &ltimeout);
						break;
				} //switch
				
				if (0 == selectStatus)
				{
					//Timeout.
					break;
				}
				else if (selectStatus < 0 || YES == stop)
				{
					break;
				}
			}			
		}		
	}
	
	if (conninfo)
		free (conninfo);
	[self finishedConnecting: retval && CONNECTION_OK == PQstatus (mConnection)];
	return retval;
}
@end



@implementation PGTSSynchronousReconnector
- (id) init
{
    if ((self = [super init]))
    {
        mPollFunction = &PQresetPoll;
    }
    return self;
}


- (BOOL) start: (const char *) connectionString
{
	return (BOOL) PQresetStart (mConnection);
}
@end
