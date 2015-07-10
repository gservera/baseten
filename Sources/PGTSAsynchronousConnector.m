//
// PGTSAsynchronousConnector.m
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


#import "PGTSAsynchronousConnector.h"
#import "PGTSConstants.h"
#import "PGTSConnection.h"
#import "BXError.h"
#import "BXLogger.h"
#import "BXEnumerate.h"
#import "BXArraySize.h"
#import <netdb.h>
#import <arpa/inet.h>


static void 
SocketReady (CFSocketRef s, CFSocketCallBackType callBackType, CFDataRef address, const void* data, void* self)
{
	[(id) self socketReady: callBackType];
}



@implementation PGTSAsynchronousConnector
- (id) init
{
	if ((self = [super init]))
	{
		mHostResolver = [[BXHostResolver alloc] init];
		[mHostResolver setDelegate: self];
		
		mExpectedCallBack = 0;
		[self setCFRunLoop: CFRunLoopGetCurrent ()];
	}
	return self;
}


- (CFRunLoopRef) CFRunLoop
{
	return mRunLoop;
}


- (void) setCFRunLoop: (CFRunLoopRef) aRef
{
	@synchronized (self)
	{
		if (mRunLoop != aRef)
		{
			if (mRunLoop)
				CFRelease (mRunLoop);
			
			mRunLoop = aRef;
			
			if (mRunLoop)
				CFRetain (mRunLoop);
		}
	}
}


- (void) setConnectionDictionary: (NSDictionary *) aDict
{
	@synchronized (self)
	{
		if (mConnectionDictionary != aDict)
		{
			[mConnectionDictionary release];
			mConnectionDictionary = [aDict retain];
		}
	}
}


- (void) freeCFTypes
{
	//Don't release the connection. Delegate will handle it.
	
	if (mSocketSource)
	{
		CFRunLoopSourceInvalidate (mSocketSource);
		CFRelease (mSocketSource);
		mSocketSource = NULL;
	}
	
	if (mSocket)
	{
		CFSocketInvalidate (mSocket);
		CFRelease (mSocket);
		mSocket = NULL;
	}
	
	if (mRunLoop)
	{
		CFRelease (mRunLoop);
		mRunLoop = NULL;
	}
}


- (void) cancel
{
	[mHostResolver cancelResolution];
    if (mConnection)
    {
        PQfinish (mConnection);
        mConnection = NULL;
    }
}


- (void) dealloc
{
	[self freeCFTypes];
	[self cancel];
	[mConnectionError release];
	[mConnectionDictionary release];
	
	[mHostResolver setDelegate: nil];
	[mHostResolver release];
	
	[super dealloc];
}


- (void) finalize
{
	[self freeCFTypes];
	[super finalize];
}


- (void) prepareToConnect
{
	ExpectL (CFRunLoopGetCurrent () == mRunLoop);
	[super prepareToConnect];
	bzero (&mHostError, sizeof (mHostError));
}


#pragma mark Callbacks

- (void) hostResolverDidSucceed: (BXHostResolver *) resolver addresses: (NSArray *) addresses
{
	ExpectL (CFRunLoopGetCurrent () == mRunLoop);
	BOOL reachedServer = NO;
	if (addresses)
	{
		char addressBuffer [40] = {}; // 8 x 4 (hex digits in IPv6 address) + 7 (colons) + 1 (nul character)
		
		NSMutableDictionary* connectionDictionary = [[mConnectionDictionary mutableCopy] autorelease];
		[connectionDictionary removeObjectForKey: kPGTSHostKey];
		
		//This is safe because each address is owned by the addresses CFArray which is owned 
		//by mHost which is CFRetained.
		BXEnumerate (addressData, e, [addresses objectEnumerator])
		{
			const struct sockaddr* address = [addressData bytes];
			sa_family_t family = address->sa_family;
			void* addressBytes = NULL;
			
			switch (family)
			{
				case AF_INET:
					addressBytes = &((struct sockaddr_in *) address)->sin_addr.s_addr;
					break;
					
				case AF_INET6:
					addressBytes = ((struct sockaddr_in6 *) address)->sin6_addr.s6_addr;
					break;
					
				default:
					break;
			}
			
			if (addressBytes && inet_ntop (family, addressBytes, addressBuffer, BXArraySize (addressBuffer)))
			{
				NSString* humanReadableAddress = [NSString stringWithUTF8String: addressBuffer];
				BXLogInfo (@"Trying '%@'", humanReadableAddress);
				[connectionDictionary setObject: humanReadableAddress forKey: kPGTSHostAddressKey];
				char* conninfo = PGTSCopyConnectionString (connectionDictionary);
				
				if ([self startNegotiation: conninfo])
				{
					reachedServer = YES;
					free (conninfo);
					break;
				}
				
				free (conninfo);
			}
		}
	}
	
	if (reachedServer)
		[self negotiateConnection];
	else
		[self finishedConnecting: NO];	
}


- (void) hostResolverDidFail: (BXHostResolver *) resolver error: (NSError *) error
{
	ExpectL (CFRunLoopGetCurrent () == mRunLoop);
	[self setConnectionError: error];		
	[self finishedConnecting: NO];
}


- (void) socketReady: (CFSocketCallBackType) callBackType
{
	BXLogDebug (@"Socket got ready.");
	ExpectL (CFRunLoopGetCurrent () == mRunLoop);
	
	//Sometimes the wrong callback type gets called. We cope with this
	//by checking against an expected type and re-enabling it if needed.
	if (callBackType != mExpectedCallBack)
		CFSocketEnableCallBacks (mSocket, mExpectedCallBack);
	else
	{
		PostgresPollingStatusType status = mPollFunction (mConnection);
		
		[self setUpSSL];
		
		switch (status)
		{
			case PGRES_POLLING_OK:
				[self finishedConnecting: YES];
				break;
				
			case PGRES_POLLING_FAILED:
				[self finishedConnecting: NO];
				break;
				
			case PGRES_POLLING_ACTIVE:
				[self socketReady: mExpectedCallBack];
				break;
				
			case PGRES_POLLING_READING:
				CFSocketEnableCallBacks (mSocket, kCFSocketReadCallBack);
				mExpectedCallBack = kCFSocketReadCallBack;
				break;
				
			case PGRES_POLLING_WRITING:
			default:
				CFSocketEnableCallBacks (mSocket, kCFSocketWriteCallBack);
				mExpectedCallBack = kCFSocketWriteCallBack;
				break;
		}
	}
}


- (void) finishedConnecting: (BOOL) succeeded
{
	ExpectL (CFRunLoopGetCurrent () == mRunLoop);
	[self freeCFTypes];
	[super finishedConnecting: succeeded];
}


#pragma mark Connection methods

- (BOOL) connect: (NSDictionary *) connectionDictionary
{
	BXLogDebug (@"Beginning connecting.");
	ExpectL (CFRunLoopGetCurrent () == mRunLoop);
	
	BOOL retval = NO;
	mExpectedCallBack = 0;
	[self prepareToConnect];
	[self setConnectionDictionary: connectionDictionary];
	
	//CFSocket etc. do some nice things for us that prevent libpq from noticing
	//connection problems. This causes SIGPIPE to be sent to us, and we get
	//"Broken pipe" as the error message. To cope with this, we check the socket's
	//status after connecting but before giving it to CFSocket.
	//For this to work, we need to resolve the host name by ourselves, if we have one.
    //If the name begins with a slash, it is a path to socket.
	
	NSString* name = [connectionDictionary objectForKey: kPGTSHostKey];
	if (0 < [name length] && '/' != [name characterAtIndex: 0])
	{
		[mHostResolver setRunLoop: mRunLoop];
		[mHostResolver setRunLoopMode: (id) kCFRunLoopCommonModes];
		[mHostResolver resolveHost: name];
	}
	else
	{
		char* conninfo = PGTSCopyConnectionString (mConnectionDictionary);
		if ([self startNegotiation: conninfo])
		{
			retval = YES;
			[self negotiateConnection];
		}
		else
		{
			[self finishedConnecting: NO];
		}
		free (conninfo);
	}
	
	return retval;
}


- (BOOL) startNegotiation: (const char *) conninfo
{
	BXLogDebug (@"Beginning negotiation.");
	ExpectL (CFRunLoopGetCurrent () == mRunLoop);

	mNegotiationStarted = NO;
	BOOL retval = NO;
	if ([self start: conninfo])
	{
		if (CONNECTION_BAD != PQstatus (mConnection))
		{
			mNegotiationStarted = YES;
			int socket = PQsocket (mConnection);
			if (socket < 0)
				BXLogInfo (@"Unable to get connection socket from libpq.");
			else
			{
				//We mimic libpq's error message because it doesn't provide us with error codes.
				//Also we need to select first to make sure that getsockopt returns an accurate error message.
				
				BOOL haveError = NO;
				NSString* reason = nil;
				
				{
					char message [256] = {};
					int status = 0;
					
					struct timeval timeout = {.tv_sec = 15, .tv_usec = 0};
					fd_set mask = {};
					FD_ZERO (&mask);
					FD_SET (socket, &mask);
					status = select (socket + 1, NULL, &mask, NULL, &timeout);		
					
					if (status <= 0)
					{
						haveError = YES;
						strerror_r (errno, message, BXArraySize (message));
						reason = [NSString stringWithUTF8String: message];
					}
					else
					{
						int optval = 0;
						socklen_t size = sizeof (optval);
						status = getsockopt (socket, SOL_SOCKET, SO_ERROR, &optval, &size);
						
						if (0 == status)
						{
							if (0 == optval)
								retval = YES;
							else
							{			
								haveError = YES;
								strerror_r (optval, message, BXArraySize (message));
								reason = [NSString stringWithUTF8String: message];
							}
						}
						else
						{
							haveError = YES;
						}
					}
				}
				
				if (haveError)
				{
					NSString* errorTitle = NSLocalizedStringWithDefaultValue (@"connectionError", nil, [NSBundle bundleForClass: [self class]],
																			  @"Connection error", @"Title for a sheet.");
					NSString* messageFormat = NSLocalizedStringWithDefaultValue (@"libpqStyleConnectionErrorFormat", nil, [NSBundle bundleForClass: [self class]],
																				 @"Could not connect to server: %@. Is the server running at \"%@\" and accepting TCP/IP connections on port %s?", 
																				 @"Reason for error");		
					if (! reason)
					{
						reason = NSLocalizedStringWithDefaultValue (@"connectionRefused", nil, [NSBundle bundleForClass: [self class]],
																	@"Connection refused", @"Reason for error");
					}
					
					NSString* address = ([mConnectionDictionary objectForKey: kPGTSHostKey] ?: [mConnectionDictionary objectForKey: kPGTSHostAddressKey]);
					NSString* message = [NSString stringWithFormat: messageFormat, reason, address, PQport (mConnection)];
					NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											  errorTitle, NSLocalizedDescriptionKey,
											  errorTitle, NSLocalizedFailureReasonErrorKey,
											  message, NSLocalizedRecoverySuggestionErrorKey,
											  nil];		
					NSError* error = [BXError errorWithDomain: kPGTSConnectionErrorDomain code: kPGTSConnectionErrorUnknown userInfo: userInfo];
					[self setConnectionError: error];
				}				
			}
		}
	}
	
	return retval;
}


- (void) negotiateConnection
{
	BXLogDebug (@"Negotiating.");
	ExpectL (CFRunLoopGetCurrent () == mRunLoop);

	if (mTraceFile)
		PQtrace (mConnection, mTraceFile);
	
	CFSocketContext context = {0, self, NULL, NULL, NULL};
	CFSocketCallBackType callbacks = kCFSocketReadCallBack | kCFSocketWriteCallBack;
	mSocket = CFSocketCreateWithNative (NULL, PQsocket (mConnection), callbacks, &SocketReady, &context);
	CFOptionFlags flags = 
	~kCFSocketAutomaticallyReenableReadCallBack &
	~kCFSocketAutomaticallyReenableWriteCallBack &
	~kCFSocketCloseOnInvalidate &
	CFSocketGetSocketFlags (mSocket);
	
	CFSocketSetSocketFlags (mSocket, flags);
	mSocketSource = CFSocketCreateRunLoopSource (NULL, mSocket, 0);
	
	BXAssertLog (mSocket, @"Expected source to have been created.");
	BXAssertLog (CFSocketIsValid (mSocket), @"Expected socket to be valid.");
	BXAssertLog (mSocketSource, @"Expected socketSource to have been created.");
	BXAssertLog (CFRunLoopSourceIsValid (mSocketSource), @"Expected socketSource to be valid.");
	
	CFSocketDisableCallBacks (mSocket, kCFSocketReadCallBack);
	CFSocketEnableCallBacks (mSocket, kCFSocketWriteCallBack);
	mExpectedCallBack = kCFSocketWriteCallBack;
	CFRunLoopAddSource (mRunLoop, mSocketSource, (CFStringRef) kCFRunLoopCommonModes);
}
@end



@implementation PGTSAsynchronousReconnector
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
	ExpectL (CFRunLoopGetCurrent () == mRunLoop);
	return (BOOL) PQresetStart (mConnection);
}
@end
