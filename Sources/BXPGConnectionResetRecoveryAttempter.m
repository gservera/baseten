//
// BXPGConnectionResetRecoveryAttempter.m
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

#import "BXPGTransactionHandler.h"
#import "BXPGConnectionResetRecoveryAttempter.h"
#import "BXDatabaseContextPrivate.h"
#import "BXDatabaseContextDelegateProtocol.h"
#import "PGTSProbes.h"


@implementation BXPGConnectionRecoveryAttempter
- (void) dealloc
{
	[mRecoveryInvocation release];
	[super dealloc];
}


- (BOOL) attemptRecoveryFromError: (NSError *) error optionIndex: (NSUInteger) recoveryOptionIndex
{
	NSError* localError = nil;
	BOOL retval = NO;
	[self allowConnecting: NO];
	if (0 == recoveryOptionIndex)
	{
		[self doAttemptRecoveryFromError: error outError: &localError];
		if (localError)
		{
			BXDatabaseContext* ctx = [[mHandler interface] databaseContext];
			[[ctx internalDelegate] databaseContext: ctx hadReconnectionError: localError];
		}
		else
		{
			retval = YES;
			[self allowConnecting: YES];
		}
	}
	return retval;
}


- (void) attemptRecoveryFromError: (NSError *) error optionIndex: (NSUInteger) recoveryOptionIndex 
						 delegate: (id) delegate didRecoverSelector: (SEL) didRecoverSelector contextInfo: (void *) contextInfo
{
	NSInvocation* i = [self recoveryInvocation: delegate selector: didRecoverSelector contextInfo: contextInfo];
	[self setRecoveryInvocation: i];
	[self allowConnecting: NO];

	if (0 == recoveryOptionIndex)
		[self doAttemptRecoveryFromError: error];
	else
		[self attemptedRecovery: NO error: nil];
}


- (void) setRecoveryInvocation: (NSInvocation *) anInvocation
{
	if (mRecoveryInvocation != anInvocation)
	{
		[mRecoveryInvocation release];
		mRecoveryInvocation = [anInvocation retain];
	}
}


- (NSInvocation *) recoveryInvocation: (id) target selector: (SEL) selector contextInfo: (void *) contextInfo
{
	NSMethodSignature* sig = [target methodSignatureForSelector: selector];
	NSInvocation* invocation = [NSInvocation invocationWithMethodSignature: sig];
	[invocation setTarget: target];
	[invocation setSelector: selector];
	[invocation setArgument: &contextInfo atIndex: 3];
	
	BOOL status = NO;
	[invocation setArgument: &status atIndex: 2];
	
	return invocation;
}


- (void) allowConnecting: (BOOL) allow
{
	[[[mHandler interface] databaseContext] setAllowReconnecting: allow];
}


- (BOOL) doAttemptRecoveryFromError: (NSError *) error outError: (NSError **) outError
{
	[self doesNotRecognizeSelector: _cmd];
	return NO;
}


- (void) doAttemptRecoveryFromError: (NSError *) error
{
	[self doesNotRecognizeSelector: _cmd];
}


- (void) attemptedRecovery: (BOOL) succeeded error: (NSError *) newError
{
	[mRecoveryInvocation setArgument: &succeeded atIndex: 2];
	[mRecoveryInvocation invoke];
	
	[self allowConnecting: succeeded];
	
	if (newError)
	{
		BXDatabaseContext* ctx = [[mHandler interface] databaseContext];
		[[ctx internalDelegate] databaseContext: ctx hadReconnectionError: newError];
	}
}
@end



@implementation BXPGConnectionRecoveryAttempter (PGTSConnectionDelegate)
- (void) PGTSConnection: (PGTSConnection *) connection gotNotification: (PGTSNotification *) notification
{
	[self doesNotRecognizeSelector: _cmd];
}


- (void) PGTSConnectionLost: (PGTSConnection *) connection error: (NSError *) error
{
	[self doesNotRecognizeSelector: _cmd];
}


- (void) PGTSConnectionFailed: (PGTSConnection *) connection
{
	[self doesNotRecognizeSelector: _cmd];
}


- (void) PGTSConnectionEstablished: (PGTSConnection *) connection
{
	[self doesNotRecognizeSelector: _cmd];
}

- (void) PGTSConnection: (PGTSConnection *) connection receivedNotice: (NSError *) notice
{
	//BXLogDebug (@"%p: %s", connection, message);
	if (BASETEN_POSTGRESQL_RECEIVED_NOTICE_ENABLED ())
	{
		NSString* message = [[notice userInfo] objectForKey: kPGTSErrorMessage];
		char* message_s = strdup ([message UTF8String]);
		BASETEN_POSTGRESQL_RECEIVED_NOTICE (connection, message_s);
		free (message_s);
	}
}

- (FILE *) PGTSConnectionTraceFile: (PGTSConnection *) connection
{
	return [mHandler PGTSConnectionTraceFile: connection];
}

- (void) PGTSConnection: (PGTSConnection *) connection sentQueryString: (const char *) queryString
{
}

- (void) PGTSConnection: (PGTSConnection *) connection sentQuery: (PGTSQuery *) query
{
}

- (void) PGTSConnection: (PGTSConnection *) connection receivedResultSet: (PGTSResultSet *) res
{
}

- (void) PGTSConnection: (PGTSConnection *) connection networkStatusChanged: (SCNetworkConnectionFlags) newFlags
{
}
@end
