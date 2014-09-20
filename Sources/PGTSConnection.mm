//
// PGTSConnection.mm
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

#import <CoreFoundation/CoreFoundation.h>
#import <BaseTen/libpq-fe.h>

#import "PGTSConnection.h"
#import "PGTSConnectionPrivate.h"
#import "PGTSConnector.h"
#import "PGTSSynchronousConnector.h"
#import "PGTSAsynchronousConnector.h"
#import "PGTSConstants.h"
#import "PGTSQuery.h"
#import "PGTSQueryDescription.h"
#import "PGTSAdditions.h"
#import "PGTSResultSet.h"
#import "PGTSDatabaseDescription.h"
#import "PGTSNotification.h"
#import "PGTSProbes.h"
#import "PGTSMetadataStorage.h"
#import "PGTSMetadataContainer.h"

#import "PGTSInvocationRecorder.h"
#import "BXLogger.h"
#import "BXEnumerate.h"
#import "BXArraySize.h"
#import "BXConstants.h"
#import "BXSocketDescriptor.h"
#import "BXConnectionMonitor.h"

#import "NSString+PGTSAdditions.h"



@interface PGTSConnection (PGTSConnectorDelegate) <PGTSConnectorDelegate>
@end



@interface PGTSConnection (BXSocketDescriptorDelegate) <BXSocketDescriptorDelegate>
@end



static void
NoticeReceiver (void *connectionPtr, PGresult const *notice)
{
	PGTSConnection *connection = (PGTSConnection *) connectionPtr;
	NSError *error = [PGTSResultSet errorForPGresult: notice];
	[[connection delegate] PGTSConnection: connection receivedNotice: error];
}



/**
 * \internal
 * \brief A connection class for Postgresql.
 * \note Instances of this class may be used from multiple threads after a connection has been made.
 */
@implementation PGTSConnection
+ (void) initialize
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
				
		{
            NSMutableArray *keys = [[[NSMutableArray alloc] init] autorelease];
			CFRetain (keys);
            PQconninfoOption *options = PQconndefaults ();
            char* keyword = NULL;
            while ((keyword = options->keyword))
            {
                NSString *key = [NSString stringWithUTF8String: keyword];
                [keys addObject: key];
                options++;
            }
			kPGTSConnectionDictionaryKeys = [keys copy];
            [keys release]; //? Added
		}
		
		[[PGTSMetadataStorage defaultStorage] setContainerClass: [PGTSEFMetadataContainer class]];
	}
}


- (id) init
{
	if ((self = [super init]))
	{
		mQueue = [[NSMutableArray alloc] init];
		mCertificateVerificationDelegate = [PGTSCertificateVerificationDelegate defaultCertificateVerificationDelegate];
	}
	return self;
}


- (void) dealloc
{
    [self disconnect];
	[self _setConnector: nil];
	
	[mQueue release];
    [mMetadataContainer release];
	[mPGTypes release];
	[super dealloc];
}


- (BOOL) connectUsingClass: (Class) connectorClass connectionDictionary: (NSDictionary *) connectionDictionary
{
	// FIXME: thread safety?

	PGTSConnector* connector = [[[connectorClass alloc] init] autorelease];
	[self _setConnector: connector];
	
	[connector setConnection: mConnection]; //For resetting.
	[connector setTraceFile: [mDelegate PGTSConnectionTraceFile: self]];
	[[BXConnectionMonitor sharedInstance] clientDidStartConnectionAttempt: self];
	BXLogDebug (@"Making %@ connect.", [connector class]);
	return [connector connect: connectionDictionary];
}


- (void) connectAsync: (NSDictionary *) connectionDictionary
{
	[self connectUsingClass: [PGTSAsynchronousConnector class] connectionDictionary: connectionDictionary];
}


- (BOOL) connectSync: (NSDictionary *) connectionDictionary
{
	return [self connectUsingClass: [PGTSSynchronousConnector class] connectionDictionary: connectionDictionary];
}


- (void) resetAsync
{
	[self connectUsingClass: [PGTSAsynchronousReconnector class] connectionDictionary: nil];
}


- (BOOL) resetSync
{
	return [self connectUsingClass: [PGTSSynchronousReconnector class] connectionDictionary: nil];
}


- (void) disconnect
{
	@synchronized (self)
	{
	    BXLogInfo (@"Disconnecting.");
		[[BXConnectionMonitor sharedInstance] clientWillDisconnect: self];

	    [mConnector cancel];
		[self _setConnector: nil];
	
	    if (mConnection)
	    {        
			PQfinish (mConnection);
	        mConnection = NULL;
		}
	}
	
	[self _setSocketDescriptor: nil];
}


- (PGconn *) pgConnection
{
	PGconn *retval = NULL;
	@synchronized (self)
	{
    	retval = mConnection;
	}
	return retval;
}


- (void) setDelegate: (id <PGTSConnectionDelegate>) anObject
{
	@synchronized (self)
	{
	    mDelegate = anObject;
	}
}


- (void) reloadDatabaseDescription
{
	BOOL shouldReload = YES;
	@synchronized (self)
	{
		if (! mMetadataContainer)
			shouldReload = NO;
	}
	
	[self databaseDescription];
	if (shouldReload)
		[mMetadataContainer reloadUsingConnection: self];
}


- (PGTSDatabaseDescription *) databaseDescription
{
	@synchronized (self)
	{
		if (! mMetadataContainer)
		{
			NSString* keyFormat = [NSString stringWithFormat: @"//%s@%s:%s/%s",
								   PQuser (mConnection), PQhost (mConnection), PQport (mConnection), PQdb (mConnection)];
			NSURL* metadataKey = [NSURL URLWithString: keyFormat];
			
			mMetadataContainer = [[[PGTSMetadataStorage defaultStorage] metadataContainerForURI: metadataKey] retain];
		}
	}
	[mMetadataContainer prepareForConnection: self];
    return [mMetadataContainer databaseDescription];
}


- (id) deserializationDictionary
{
	@synchronized (self)
	{
		if (! mPGTypes)
		{
			NSBundle* bundle = [NSBundle bundleForClass: [PGTSConnection class]];
			NSString* path = [[bundle resourcePath] stringByAppendingString: @"/datatypeassociations.plist"];
			NSData* plist = [NSData dataWithContentsOfFile: path];
			BXAssertValueReturn (plist, nil, @"datatypeassociations.plist was not found (looked from %@).", path);
			
			NSError* error = nil;
			NSMutableDictionary *PGTypes = [[[NSPropertyListSerialization propertyListWithData:plist options:NSPropertyListImmutable format:NULL error:&error] mutableCopy] autorelease];
            
			BXAssertValueReturn (PGTypes, nil, @"Error creating PGTSDeserializationDictionary: %@ (file: %@)", [error localizedDescription], path);
			
			NSArray* keys = [PGTypes allKeys];
			BXEnumerate (key, e, [keys objectEnumerator])
			{
				Class typeClass = NSClassFromString ([PGTypes objectForKey: key]);
				if (Nil == typeClass)
					[PGTypes removeObjectForKey: key];
				else
					[PGTypes setObject: typeClass forKey: key];
			}
			
			mPGTypes = [PGTypes copy];
		}
	}
    return mPGTypes;
}


- (NSString *) errorString
{
	NSString *message = nil;
	@synchronized (self)
	{
		message = [NSString stringWithUTF8String: PQerrorMessage (mConnection)];
	}
	message = PGTSReformatErrorMessage (message);
	return message;
}


- (NSError *) connectionError
{
	// FIXME: thread safety?
	return [mConnector connectionError];
}


- (id <PGTSCertificateVerificationDelegate>) certificateVerificationDelegate
{
	id <PGTSCertificateVerificationDelegate> retval = nil;
	@synchronized (self)
	{
		retval = [[mCertificateVerificationDelegate retain] autorelease];
	}
	return retval;
}


- (void) setCertificateVerificationDelegate: (id <PGTSCertificateVerificationDelegate>) anObject
{
	@synchronized (self)
	{
		mCertificateVerificationDelegate = anObject;
		if (! mCertificateVerificationDelegate)
			mCertificateVerificationDelegate = [PGTSCertificateVerificationDelegate defaultCertificateVerificationDelegate];
	}
}


- (ConnStatusType) connectionStatus
{
	ConnStatusType retval = CONNECTION_OK;
	@synchronized (self)
	{
		retval = PQstatus (mConnection);
	}
	return retval;
}


- (PGTransactionStatusType) transactionStatus
{
	PGTransactionStatusType retval = PQTRANS_IDLE;
	@synchronized (self)
	{
		retval = PQtransactionStatus (mConnection);
	}
	return retval;
}


- (int) backendPID
{
	int retval = 0;
	@synchronized (self)
	{
		retval = PQbackendPID (mConnection);
	}
	return retval;
}


- (int) socket
{
	int retval = 0;
	@synchronized (self)
	{
		retval = PQsocket (mConnection);
	}
	return retval;
}


- (BXSocketDescriptor *) socketDescriptor
{
	id retval = nil;
	@synchronized (self)
	{
		retval = [[mSocketDescriptor retain] autorelease];
	}
	return retval;
}


- (PGresult *) execQuery: (const char *) query
{
	PGresult *res = NULL;

	@synchronized (self)
	{
		Expect (! mSocketDescriptor || [mSocketDescriptor isLocked]);

		if ([self canSend])
		{
			res = PQexec (mConnection, query);
			if (BASETEN_POSTGRESQL_SEND_QUERY_ENABLED ())
			{
				char *query_s = strdup (query);
				BASETEN_POSTGRESQL_SEND_QUERY (self, 1, query_s, NULL);
				free (query_s);
			}
		}
	}
	
	if (res && mLogsQueries)
		[mDelegate PGTSConnection: self sentQueryString: query];
	
	return res;
}


- (id <PGTSConnectionDelegate>) delegate
{
	id <PGTSConnectionDelegate> retval = nil;
	@synchronized (self)
	{
		retval = [[mDelegate retain] autorelease];
	}
	return retval;
}


- (BOOL) logsQueries
{
	BOOL retval = NO;
	@synchronized (self)
	{
		retval = mLogsQueries;
	}
	return retval;
}


- (void) setLogsQueries: (BOOL) flag
{
	@synchronized (self)
	{
		mLogsQueries = flag;
	}
}


- (void) logQueryIfNeeded: (PGTSQuery *) query
{
	if (mLogsQueries)
		[mDelegate PGTSConnection: self sentQuery: query];
}


- (void) logResultIfNeeded: (PGTSResultSet *) res
{
	if (mLogsQueries)
		[mDelegate PGTSConnection: self receivedResultSet: res];
}


- (SSL *) SSLStruct
{
	SSL *retval = NULL;
	@synchronized (self)
	{
		retval = (SSL *) PQgetssl (mConnection);
	}
	return retval;
}


- (BOOL) canSend
{
	//FIXME: rewrite
	return YES;
}


- (BOOL) usedPassword
{
	BOOL retval = NO;
	@synchronized (self)
	{
		retval = (PQconnectionUsedPassword (mConnection) ? YES : NO);
	}
	return retval;
}
@end



@implementation PGTSConnection (PGTSConnectionPrivate)
- (void) _setConnector: (PGTSConnector *) anObject
{
	@synchronized (self)
	{
		if (mConnector != anObject)
		{
			[mConnector cancel];
			[mConnector setDelegate: nil];
			[mConnector release];
			
			mConnector = [anObject retain];
			[(PGTSConnector*)mConnector setDelegate: (id <PGTSConnectorDelegate>)self];
		}
	}
}


- (void) _setSocketDescriptor: (BXSocketDescriptor *) desc
{
	BXSocketDescriptor *oldDesc = nil;
	@synchronized (self)
	{
		oldDesc = mSocketDescriptor;
		
		mSocketDescriptor = [desc retain];
		[mSocketDescriptor setDelegate: self];
		[mSocketDescriptor install];
	}
	
	[oldDesc invalidate];
	[oldDesc setDelegate: nil];
	[oldDesc release];
}


- (void) _processNotifications
{
	NSMutableArray *notifications = nil;
	
	@synchronized (self)
	{
		PGnotify* pgNotification = NULL;
		while ((pgNotification = PQnotifies (mConnection)))
		{
			if (! notifications)
				notifications = [[NSMutableArray alloc] init];
			
			NSString* name = [NSString stringWithUTF8String: pgNotification->relname];
			PGTSNotification* notification = [[PGTSNotification alloc] init];
			[notification setBackendPID: pgNotification->be_pid];
			[notification setNotificationName: name];
			BASETEN_POSTGRESQL_RECEIVED_NOTIFICATION (self, pgNotification->be_pid, pgNotification->relname, pgNotification->extra);		
			PQfreeNotify (pgNotification);
			
			[notifications addObject: notification];
			[notification release];
		}    
	}

	if ([notifications count])
	{
		BXLogInfo (@"Received %lu notifications.", (unsigned long)[notifications count]);
		id <PGTSConnectionDelegate> delegate = [self delegate];
		for (PGTSNotification *notification in notifications)
			[delegate PGTSConnection: self gotNotification: notification];
	}
	
	[notifications release];
}


- (void) _sendNextQuery
{
	ExpectV ([mSocketDescriptor isLocked]);

	@synchronized (self)
	{
		if ([mQueue count])
		{
			PGTSQueryDescription* desc = [mQueue objectAtIndex: 0];
			if (nil != desc)
			{
				BXAssertVoidReturn (! [desc sent], @"Expected %@ not to have been sent.", desc);	
				
				[desc sendForConnection: self];
				[self _checkConnectionStatus];
			}
		}
	}
}


- (void) _sendOrEnqueueQuery: (PGTSQueryDescription *) query
{	
	@synchronized (self)
	{
		[mQueue addObject: query];
		if (1 == [mQueue count] && mConnection)
		{
			NSInvocation *invocation = nil;
			[[PGTSInvocationRecorder recordWithTarget: self outInvocation: &invocation] _sendNextQuery];
			[mSocketDescriptor lock: invocation];
		}
	}
}


- (void) _checkConnectionStatus
{
	@synchronized (self)
	{
		if (CONNECTION_BAD == PQstatus (mConnection))
			[mDelegate PGTSConnectionLost: self error: nil]; //FIXME: set the error.
		//FIXME: also indicate that a reset will be sufficient instead of reconnecting.
	}
}


- (PGTSResultSet *) _executeQuery: (NSString *) queryString parameterArray: (NSArray *) parameters
{
	PGTSResultSet *retval = nil;
	@synchronized (self)
	{
		//First empty the query queue.
		{
			PGTSResultSet* res = nil;
			PGTSQueryDescription* desc = nil;
			while (0 < [mQueue count] && (desc = [mQueue objectAtIndex: 0])) 
			{
				res = [desc finishForConnection: self];
				if ([mQueue count]) //Patch by Jianhua Meng 2008-11-12
					[mQueue removeObjectAtIndex: 0];		
			}
		}
		
		// Send the actual query.
		PGTSQueryDescription* desc = [PGTSQueryDescription queryDescriptionFor: queryString 
																	  delegate: nil
																	  callback: NULL 
																parameterArray: parameters
																	  userInfo: nil];
		retval = [desc finishForConnection: self];
	}
	return retval;
}
@end




@implementation PGTSConnection (PGTSConnectorDelegate)
- (void) connector: (PGTSConnector*) connector gotConnection: (PGconn *) connection
{
	mConnection = connection;
	
	//Rather than call PQsendquery etc. multiple times, monitor the socket state.
	PQsetnonblocking (connection, 0); 
	//Use UTF-8.
	PQsetClientEncoding (connection, "UNICODE"); 
	
	BOOL shouldContinue = YES;
	char const * const queries [] = {
		"SET standard_conforming_strings TO true",
		"SET datestyle TO 'ISO, YMD'",
		"SET timezone TO 'UTC'",
		"SET transaction_isolation TO 'read committed'"
	};
	for (int i = 0, count = BXArraySize (queries); i < count; i++)
	{
		PGresult* res = [self execQuery: queries [i]];
		if (PGRES_COMMAND_OK != PQresultStatus (res))
		{
			shouldContinue = NO;
			BXLogError (@"Expected setting run-time parameters for connection to succeed. Error:\n%s",
						PQresultErrorMessage (res) ?: "<no error message>");
			
			PGTSResultSet* result = [[[PGTSResultSet alloc] initWithPGResult: res connection: self] autorelease];
			NSError* error = [result error];
			[mConnector setConnectionError: error];
		}
	}
	
	int const serverVersion = PQserverVersion (connection);
	if (serverVersion < 90000)
	{
		PGresult* res = [self execQuery: "SET regex_flavor TO 'advanced'"];
		if (PGRES_COMMAND_OK != PQresultStatus (res))
		{
			shouldContinue = NO;
			BXLogError (@"Expected setting run-time parameters for connection to succeed. Error:\n%s",
						PQresultErrorMessage (res) ?: "<no error message>");
			
			PGTSResultSet* result = [[[PGTSResultSet alloc] initWithPGResult: res connection: self] autorelease];
			NSError* error = [result error];
			[mConnector setConnectionError: error];
		}
	}

	if (shouldContinue)
	{
		PQsetNoticeReceiver (connection, &NoticeReceiver, (void *) self);
		
		BXSocketDescriptor *desc = [BXSocketDescriptor copyDescriptorWithSocket: PQsocket (mConnection)];
		[self _setSocketDescriptor: desc];
		[desc release];
		
		[[BXConnectionMonitor sharedInstance] clientDidConnect: self];
		
		if (0 < [mQueue count])
		{
			NSInvocation *invocation = nil;
			[[PGTSInvocationRecorder recordWithTarget: self outInvocation: &invocation] _sendNextQuery];
			[mSocketDescriptor lock: invocation];
		}
		
		[mDelegate PGTSConnectionEstablished: self];
		[self _setConnector: nil];
	}
	else
	{
		[[BXConnectionMonitor sharedInstance] clientDidFailConnectionAttempt: self];
        [mDelegate PGTSConnectionFailed: self];
	}
}


- (void) connectorFailed: (PGTSConnector*) connector
{
	[[BXConnectionMonitor sharedInstance] clientDidFailConnectionAttempt: self];
	[mDelegate PGTSConnectionFailed: self];
	//Retain the connector for error handling.
}


- (BOOL) allowSSLForConnector: (PGTSConnector *) connector context: (void *) x509_ctx preverifyStatus: (int) preverifyStatus
{
	return [mCertificateVerificationDelegate PGTSAllowSSLForConnection: self context: x509_ctx preverifyStatus: preverifyStatus];
}
@end



@implementation PGTSConnection (BXSocketDescriptorDelegate)
- (void) socketDescriptor: (BXSocketDescriptor *) desc readyForReading: (int) fd estimatedSize: (unsigned long) size
{
	@synchronized (self)
	{
		ExpectV ([desc isLocked]);

		//When the socket is ready for read, send any available notifications and read results until 
		//the socket blocks. If all results for the current query have been read, send the next query.
		PQconsumeInput (mConnection);
		
		[self _processNotifications];
		
		if (0 < [mQueue count])
		{
			PGTSQueryDescription* queryDescription = [[[mQueue objectAtIndex: 0] retain] autorelease];
			while (! PQisBusy (mConnection))
			{
				[queryDescription receiveForConnection: self];
				if ([queryDescription finished])
					break;
			}
			
			if ([queryDescription finished])
			{
				NSUInteger count = [mQueue count];
				if (count)
				{
					if ([mQueue objectAtIndex: 0] == queryDescription)
					{
						[mQueue removeObjectAtIndex: 0];
						count--;
					}
					
					if (count)
						[self _sendNextQuery];
				}            
			}
		}
	}
}


- (void) socketDescriptor: (BXSocketDescriptor *) desc lockedSocket: (int) fd userInfo: (id) userInfo
{
	ExpectV ([userInfo isKindOfClass: [NSInvocation class]]);
	[userInfo invoke];
}
@end



@implementation PGTSConnection (Queries)
#define StdargToNSArray( ARRAY_VAR, COUNT, LAST ) \
    { va_list ap; va_start (ap, LAST); ARRAY_VAR = StdargToNSArray2 (ap, COUNT, LAST); va_end (ap); }


static NSArray*
StdargToNSArray2 (va_list arguments, int argCount, id lastArg)
{
    NSMutableArray* retval = [NSMutableArray arrayWithCapacity: argCount];
	if (0 < argCount)
	{
		[retval addObject: lastArg ?: [NSNull null]];

	    for (int i = 1; i < argCount; i++)
    	{
        	id argument = va_arg (arguments, id);
	        [retval addObject: argument ?: [NSNull null]];
    	}
	}
    return retval;
}


/**
 * \internal
 * \brief The number of parameters in a string.
 *
 * Parameters are marked as follows: $n. The number of parameters is equal to the highest value of n.
 */
static int
ParameterCount (NSString* query)
{
    NSScanner* scanner = [NSScanner scannerWithString: query];
    int paramCount = 0;
    while (NO == [scanner isAtEnd])
    {
        int foundCount = 0;
        [scanner scanUpToString: @"$" intoString: NULL];
        [scanner scanString: @"$" intoString: NULL];
        //The largest found number specifies the number of parameters
        if ([scanner scanInt: &foundCount])
            paramCount = MAX (foundCount, paramCount);
    }
    return paramCount;
}


- (PGTSResultSet *) executeQuery: (NSString *) queryString
{
	return [self executeQuery: queryString parameterArray: nil];
}


- (PGTSResultSet *) executeQuery: (NSString *) queryString parameters: (id) p1, ...
{
	NSArray* parameters = nil;
	StdargToNSArray (parameters, ParameterCount (queryString), p1);
	return [self executeQuery: queryString parameterArray: parameters];
}


- (PGTSResultSet *) executeQuery: (NSString *) queryString parameterArray: (NSArray *) parameters
{
	NSInvocation *invocation = nil;
	PGTSResultSet *retval = nil;
	
	[[PGTSInvocationRecorder recordWithTarget: self outInvocation: &invocation] 
	 _executeQuery: queryString parameterArray: parameters];
	
	// Remember not to call -lockAndWait: while @synchronized. Otherwise we'll deadlock.
	[mSocketDescriptor lockAndWait: invocation];
	[invocation getReturnValue: &retval];
	
	return retval;
}


- (int) sendQuery: (NSString *) queryString delegate: (id) delegate callback: (SEL) callback
{
	return [self sendQuery: queryString delegate: delegate callback: callback parameterArray: nil];
}


- (int) sendQuery: (NSString *) queryString delegate: (id) delegate callback: (SEL) callback
	   parameters: (id) p1, ...
{
	NSArray* parameters = nil;
	StdargToNSArray (parameters, ParameterCount (queryString), p1);
	return [self sendQuery: queryString delegate: delegate callback: callback parameterArray: parameters];
}


- (int) sendQuery: (NSString *) queryString delegate: (id) delegate callback: (SEL) callback 
   parameterArray: (NSArray *) parameters
{
	return [self sendQuery: queryString delegate: delegate callback: callback 
			parameterArray: parameters userInfo: nil];
}


- (int) sendQuery: (NSString *) queryString delegate: (id) delegate callback: (SEL) callback 
   parameterArray: (NSArray *) parameters userInfo: (id) userInfo
{
	PGTSQueryDescription* desc = [PGTSQueryDescription queryDescriptionFor: queryString 
																  delegate: delegate 
																  callback: callback
															parameterArray: parameters
																  userInfo: userInfo];
	int retval = (int)[desc identifier];
	[self _sendOrEnqueueQuery: desc];
	return retval;
}
@end



@implementation PGTSConnection (BXConnectionMonitorClient)
- (int) socketForConnectionMonitor: (BXConnectionMonitor *) monitor
{
	return [self socket];
}


- (void) connectionMonitorProcessWillExit: (BXConnectionMonitor *) monitor
{
    [self disconnect];
}


- (void) connectionMonitorSystemWillSleep: (BXConnectionMonitor *) monitor
{
 	[self disconnect];
	mDidDisconnectOnSleep = YES;
}


- (void) connectionMonitorSystemDidWake: (BXConnectionMonitor *) monitor
{
	if (mDidDisconnectOnSleep)
	{
		mDidDisconnectOnSleep = NO;
		[mDelegate PGTSConnectionLost: self error: nil]; //FIXME: set the error.
	}
}


- (void) connectionMonitor: (BXConnectionMonitor *) monitor
	  networkStatusChanged: (SCNetworkConnectionFlags) flags
{
	[mDelegate PGTSConnection: self networkStatusChanged: flags];
}
@end
