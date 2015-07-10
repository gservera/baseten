//
// PGTSConnection.m
// BaseTen
//
// Copyright 2006-2008 Marko Karppinen & Co. LLC.
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

#import <PGTS/postgresql/libpq-fe.h> 

#ifdef USE_SSL
#import <openssl/ssl.h>
#endif

#import "TSRunloopMessenger.h"

#import "PGTSConnectionPrivate.h"
#import "PGTSConnection.h"
#import "PGTSResultSetPrivate.h"
#import "PGTSResultSet.h"
#import "PGTSAdditions.h"
#import "PGTSConnectionPool.h"
#import "PGTSConstants.h"
#import "PGTSConnectionDelegate.h"
#import "PGTSFunctions.h"
#import "PGTSDatabaseInfo.h"
#import "PGTSCertificateVerificationDelegate.h"
#import <MKCCollections/MKCCollections.h>
#import <Log4Cocoa/Log4Cocoa.h>


/** \cond */

#define BlockWhileConnecting( CONNECTION_CALL ) { \
    messageDelegateAfterConnecting = NO; \
    if (YES == CONNECTION_CALL) \
	{ \
        [asyncConnectionLock lockWhenCondition: 1]; \
		[asyncConnectionLock unlockWithCondition: 0]; \
	} \
    messageDelegateAfterConnecting = YES; \
    [self finishConnecting]; \
}


#define AssociateSelector( SEL, EXCEPTBIT ) { selector: SEL, exceptBit: EXCEPTBIT }


struct exceptionAssociation
{
    SEL selector;
    int exceptBit;
};

/** \endcond */


static id <PGTSCertificateVerificationDelegate> defaultCertDelegate = nil;

/**
 * Return the result of the given accessor as an NSString
 * Handles returned NULL values safely
 */
static inline NSString*
SafeStatusAccessor (char* (*function)(const PGconn*), PGconn* connection)
{
    char* value = function (connection);
    NSString* rval = nil;
    if (NULL != value)
        rval = [NSString stringWithUTF8String: value];
    return rval;
}

/**
 * Raise an exception if the delegate is invalid
 * Checks from a cache whether the delegate responds to a given selector
 * and raises and exception if needed
 */
static void
CheckExceptionTable (PGTSConnection* sender, int bitMask, BOOL doCheck)
{
    if (doCheck && sender->exceptionTable & bitMask)
    {
        id delegate = [sender delegate];
        NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
            sender, kPGTSConnectionKey, delegate, kPGTSConnectionDelegateKey, nil];
        NSString* reason = NSLocalizedString (@"Asynchronous connecting not allowed for delegate %p; missing methods", @"Exception reason");
        NSException* e = [NSException exceptionWithName: NSInternalInconsistencyException 
                                                 reason: [NSString stringWithFormat: reason, delegate]
                                               userInfo: userInfo];
        [e raise];
    }
}

/** Database connection */
@implementation PGTSConnection

/** Returns an autoreleased connection object */
+ (PGTSConnection *) connection
{
	return [[[[self class] alloc] init] autorelease];
}

+ (void) initialize
{
	static BOOL tooLate = NO;
	if (!tooLate)
	{
		tooLate = YES;
        
        kPGTSSentQuerySelector                  = @selector (PGTSConnection:sentQuery:);
        kPGTSFailedToSendQuerySelector          = @selector (PGTSConnection:failedToSendQuery:);
        kPGTSAcceptCopyingDataSelector          = @selector (PGTSConnection:acceptCopyingData:errorMessage:);
        kPGTSReceivedDataSelector               = @selector (PGTSConnection:receivedData:);
        kPGTSReceivedResultSetSelector          = @selector (PGTSConnection:receivedResultSet:);
        kPGTSReceivedErrorSelector              = @selector (PGTSConnection:receivedError:);
        kPGTSReceivedNoticeSelector             = @selector (PGTSConnection:receivedNotice:);
        
        kPGTSConnectionFailedSelector           = @selector (PGTSConnectionFailed:);
        kPGTSConnectionEstablishedSelector      = @selector (PGTSConnectionEstablished:);
        kPGTSStartedReconnectingSelector        = @selector (PGTSConnectionStartedReconnecting:);
        kPGTSDidReconnectSelector               = @selector (PGTSConnectionDidReconnect:);
        
        {
            NSMutableArray* keys = [NSMutableArray array];
            kPGTSDefaultConnectionDictionary = [[NSMutableDictionary alloc] init];
            
            PQconninfoOption *option = PQconndefaults ();
            char* keyword = NULL;
            while ((keyword = option->keyword))
            {
                NSString* key = [NSString stringWithUTF8String: keyword];
                [keys addObject: key];
                char* value = option->val;
                if (NULL == value)
                    value = getenv ([key UTF8String]);
                if (NULL == value)
                    value = option->compiled;
                if (NULL != value)
                {
                    [(NSMutableDictionary *) kPGTSDefaultConnectionDictionary setObject: 
                                          [NSString stringWithUTF8String: value] forKey: key];
                }
                option++;
            }
            kPGTSConnectionDictionaryKeys = [keys copy];
			
			//sslmode is disabled by default??
			[(NSMutableDictionary *) kPGTSDefaultConnectionDictionary setObject: @"prefer" forKey: @"sslmode"];
        }		
        defaultCertDelegate = [[PGTSCertificateVerificationDelegate alloc] init];
	}
}

- (id) init
{    
    if ((self = [super init]))
    {
        connection = NULL;
        connectionLock = [[NSLock alloc] init];
        connectionStatus = CONNECTION_BAD;
        messageDelegateAfterConnecting = YES;
        //socket is managed by the worker thread
        cancelRequest = NULL;
        timeout.tv_sec = 10;
        timeout.tv_usec = 0;
        
        workerThreadLock = [[NSLock alloc] init];
        asyncConnectionLock = [[NSConditionLock alloc] initWithCondition: 0];
        
        postgresNotificationCenter = [[NSNotificationCenter PGTSNotificationCenter] retain];
        notificationCounts = [[NSCountedSet alloc] init];
        notificationAssociations = [[NSMutableDictionary alloc] init];
        
        [self setConnectionDictionary: kPGTSDefaultConnectionDictionary];
        
        resultSetClass = [PGTSResultSet class];
        
        parameterCounts = [MKCDictionary copyDictionaryWithKeyType: kMKCCollectionTypeObject 
                                                         valueType: kMKCCollectionTypeInteger];
        delegateProcessesNotices = NO;
        overlooksFailedQueries = YES;
        connectsAutomatically = NO;
        reconnectsAutomatically = NO;
        logsQueries = NO;
        failedToSendQuery = NO;
        initialCommands = nil;
        //databaseInfo is set after the connection has been made
		certificateVerificationDelegate = defaultCertDelegate;
        
        exceptionTable = 0;
        [self setDelegate: nil];        

        id messenger = [TSRunloopMessenger runLoopMessengerForCurrentRunLoop];
        mainProxy          = [[messenger target: self withResult: NO]  retain];
        returningMainProxy = [[messenger target: self withResult: YES] retain];
        NSConditionLock* threadStartLock = [[NSConditionLock alloc] initWithCondition: 0];

        //Wait for the worker thread to start
        [NSThread detachNewThreadSelector: @selector (workerThreadMain:) toTarget: self withObject: threadStartLock];
        [threadStartLock lockWhenCondition: 1];
        [threadStartLock unlock];
        [threadStartLock release];        
    }
	return self;
}

/**
 * Construct a similiar connection object without actually connecting to the database.
 */
- (id) disconnectedCopy
{
    PGTSConnection* anObject = [[[self class] alloc] init];
    anObject->timeout = timeout;
    [anObject setConnectionString: connectionString];
    [anObject setDeserializationDictionary: deserializationDictionary];
    anObject->connectsAutomatically = connectsAutomatically;
    anObject->reconnectsAutomatically = reconnectsAutomatically;
    anObject->overlooksFailedQueries = overlooksFailedQueries;
    [anObject setInitialCommands: initialCommands];
    anObject->resultSetClass = resultSetClass;
    [anObject setDelegate: delegate];
    anObject->logsQueries = logsQueries;
    
    return anObject;
}

- (void) dealloc
{
    [self disconnect];
    //Wait for the other thread to end
    [self endWorkerThread];
    
	[postgresNotificationCenter release];
    [notificationCounts release];
    [notificationAssociations release];
	
    [connectionLock release];
    [asyncConnectionLock release];
    [workerThreadLock release];
        
    [connectionString release];
    [parameterCounts release];
	[deserializationDictionary release];
    [initialCommands release];
	[errorMessage release];
    
    log4Debug (@"Deallocating db connection: %p", self);
    [super dealloc];
}

/**
 * Connect or reconnect asynchronously.
 * The delegate is required to respond to some related messages
 */
//@{
- (BOOL) connectAsync
{
    BOOL rval = NO;
    CheckExceptionTable (self, kPGTSRaiseForConnectAsync, messageDelegateAfterConnecting);

	if (NO == connecting)
	{
		connecting = YES;
		connectingAsync = YES;
	}
	
	[connectionLock lock];
	if (NULL != connection)
	{
		PQfinish (connection);
		connection = NULL;
	}
	[connectionLock unlock];
	
	const char* conninfo = [connectionString UTF8String];
	if ((connection = PQconnectStart (conninfo)))
	{
		rval = YES;
		[workerProxy workerPollConnectionResetting: NO];
	}
	else
	{
		connecting = NO;
	}
	
    return rval;
}

- (BOOL) reconnectAsync
{
    BOOL rval = NO;
    CheckExceptionTable (self, kPGTSRaiseForReconnectAsync, messageDelegateAfterConnecting);
    if (NULL != connection && 1 == PQresetStart (connection))
    {
        rval = YES;
        [workerProxy workerPollConnectionResetting: YES];
    }    
    return rval;
}
//@}

/**
 * Connect or reconnect synchronously
 */
//@{
- (ConnStatusType) connect
{
	connecting = YES;
    BlockWhileConnecting ([self connectAsync]);
	connecting = NO;
    return connectionStatus;
}

- (ConnStatusType) reconnect
{
    if (CONNECTION_OK != connectionStatus)
        BlockWhileConnecting ([self reconnectAsync]);
    return connectionStatus;
}
//@}

/**
 * End the worker thread
 */
- (void) endWorkerThread
{
	if (YES == shouldContinueThread)
	{
		messageDelegateAfterConnecting = NO;
		[asyncConnectionLock lock];
		[asyncConnectionLock unlock];
		[workerProxy workerEnd];
		[workerThreadLock lock];
		[workerThreadLock unlock];
		
		[mainProxy release];
		[returningMainProxy release];
		mainProxy = nil;
		returningMainProxy = nil;
	}
}


/**
 * Disconnect from the database
 */
- (void) disconnect
{
   if (NULL != connection)
   {
       [asyncConnectionLock lock];
       [asyncConnectionLock unlock];
       NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
       [nc postNotificationName: kPGTSWillDisconnectNotification object: self];
       [[PGTSConnectionPool sharedInstance] removeConnection: self];
       
	   [returningWorkerProxy workerCleanUpDisconnecting: YES];	   
       [nc postNotificationName: kPGTSDidDisconnectNotification object: self];
   }
}

- (NSNotificationCenter *) postgresNotificationCenter
{
    return postgresNotificationCenter;
}

/**
 * Send a LISTEN query and register an object to receive notifications from this connection
 * \param anObject The observer
 * \param aSelector The method to be called upon notification. It should take one parameter the type of which is NSNotification
 */
- (void) startListening: (id) anObject forNotification: (NSString *) notificationName selector: (SEL) aSelector
{    
    [self startListening: anObject forNotification: notificationName 
                selector: aSelector sendQuery: YES];
}

- (void) startListening: (id) anObject forNotification: (NSString *) notificationName 
               selector: (SEL) aSelector sendQuery: (BOOL) sendQuery
{
    //Keep track of listeners although this should probably be done in the NotificationCenter
    NSValue* objectIdentifier = [NSValue valueWithPointer: anObject];
    NSMutableSet* objectNotifications = [notificationAssociations objectForKey: objectIdentifier];
    if (nil == objectNotifications)
    {
        objectNotifications = [NSMutableSet set];
        [notificationAssociations setObject: objectNotifications forKey: objectIdentifier];
    }
    else if ([objectNotifications containsObject: notificationName])
        return; //We already were listening
    
    [postgresNotificationCenter addObserver: anObject 
                                   selector: aSelector
                                       name: notificationName 
                                     object: self];    
    if (sendQuery && ![notificationCounts containsObject: notificationName])
    {
        [self executeQuery: [NSString stringWithFormat: @"LISTEN \"%@\"", notificationName]];
    }
    
    [objectNotifications addObject: notificationName];
    [notificationCounts addObject: notificationName];
}

/**
 * Remove an object as the observer of notifications with the given name
 * An UNLISTEN query is also sent if the object is the only observer for the given notification
 */
- (void) stopListening: (id) anObject forNotification: (NSString *) notificationName
{
    NSValue* objectIdentifier = [NSValue valueWithPointer: anObject];
    NSMutableSet* objectNotifications = [notificationAssociations objectForKey: objectIdentifier];
    if ([objectNotifications containsObject: notificationName])
    {
        [objectNotifications removeObject: notificationName];
        [notificationCounts removeObject: notificationName];
        if (![notificationCounts containsObject: notificationName])
        {
            [self executeQuery: [@"UNLISTEN " stringByAppendingString: notificationName]];
        }
        
        [postgresNotificationCenter removeObserver: anObject 
                                              name: notificationName 
                                            object: self];
    }
}

/**
 * Remove an object as the observer of any notifications
 */
- (void) stopListening: (id) anObject
{
    NSValue* objectIdentifier = [NSValue valueWithPointer: anObject];
    NSEnumerator* e = [[notificationAssociations objectForKey: objectIdentifier] objectEnumerator];
    NSString* notificationName;

    [notificationAssociations removeObjectForKey: objectIdentifier];
    [postgresNotificationCenter removeObserver: anObject];
	
    while ((notificationName = [e nextObject]))
    {
        [notificationCounts removeObject: notificationName];
        if (![notificationCounts containsObject: notificationName])
			[self executeQuery: [@"UNLISTEN " stringByAppendingString: notificationName]];
    }
}

@end


/** Miscellaneous accessors */
@implementation PGTSConnection (MiscAccessors)

/** Returns YES if OpenSSL was linked at compile time */
+ (BOOL) hasSSLCapability
{
#ifdef USE_SSL
    return YES;
#else
    return NO;
#endif
}

/** Connection status */
- (ConnStatusType) status
{
    return connectionStatus;
}

/** The connection object from libpq */
- (PGconn *) pgConnection
{
    return connection;
}

/**
 * Connection variables.
 */
//@{
- (BOOL) setConnectionURL: (NSURL *) url
{
    log4Debug (@"Connection URL: %@", url);
	BOOL rval = NO;
	NSDictionary* connectionDict = [url PGTSConnectionDictionary];
	if (nil != connectionDict)
	{
		[self setConnectionDictionary: connectionDict];
		rval = YES;
	}	
    return rval;
}

/** \sa PGTSConstants.h for keys */
- (void) setConnectionDictionary: (NSDictionary *) userDict
{
    NSMutableDictionary* connectionDict = [[kPGTSDefaultConnectionDictionary mutableCopy] autorelease];
    [connectionDict addEntriesFromDictionary: userDict];
	
	if (nil == [connectionDict objectForKey: kPGTSConnectTimeoutKey])
	{
		int seconds = [self timeout].tv_sec;
		[connectionDict setObject: [NSNumber numberWithInt: seconds] forKey: kPGTSConnectTimeoutKey];
	}
	
    [self setConnectionString: [connectionDict PGTSConnectionString]];
}

/** Set the connection string directly */
- (void) setConnectionString: (NSString *) aString
{
    if (connectionString != aString)
    {
        [connectionString release];
        connectionString = [aString retain];
    }
}
//@}

/** Return the connection string set using an NSDictionary or NSString */
- (NSString *) connectionString
{
    return connectionString;
}

/**
 * The delegate
 */
//@{
- (id <PGTSConnectionDelegate>) delegate
{
    return delegate;
}

- (void) setDelegate: (id <PGTSConnectionDelegate>) anObject
{    
    delegate = anObject;
    
    delegateProcessesNotices = NO;
    if ([anObject respondsToSelector: kPGTSReceivedNoticeSelector])
        delegateProcessesNotices = YES;
    
    struct exceptionAssociation associations [] =
    {
        //AssociateSelector (kPGTSSentQuerySelector, kPGTSRaiseForCompletelyAsync),
        AssociateSelector (kPGTSFailedToSendQuerySelector, kPGTSRaiseForCompletelyAsync),
        AssociateSelector (kPGTSAcceptCopyingDataSelector, kPGTSRaiseForSendCopyData),
        AssociateSelector (kPGTSReceivedDataSelector, kPGTSRaiseForReceiveCopyData),
        AssociateSelector (kPGTSReceivedResultSetSelector, kPGTSRaiseForAsync),
        //AssociateSelector (kPGTSReceivedErrorSelector, kPGTSRaiseForAsync),
        
        AssociateSelector (kPGTSConnectionFailedSelector, kPGTSRaiseForConnectAsync),
        AssociateSelector (kPGTSConnectionEstablishedSelector, kPGTSRaiseForConnectAsync),
        AssociateSelector (kPGTSConnectionFailedSelector, kPGTSRaiseForReconnectAsync),
        AssociateSelector (kPGTSDidReconnectSelector, kPGTSRaiseForReconnectAsync),

        AssociateSelector (NULL, 0)
    };
    
    for (int i = 0; NULL != associations [i].selector; i++)
    {
        //Cancel only the exceptions the delegate is responsible for
        exceptionTable &= ~associations [i].exceptBit;
    }

    for (int i = 0; NULL != associations [i].selector; i++)
    {
        if (NO == [anObject respondsToSelector: associations [i].selector])
            exceptionTable |= associations [i].exceptBit;
    }    
}
//@}

- (BOOL) overlooksFailedQueries
{
    return overlooksFailedQueries;
}

/**
 * Set the framework to call PGTSConnection:receivedResultSet: instead of PGTSConnection:receivedError:
 */
- (void) setOverlooksFailedQueries: (BOOL) aBool
{
    overlooksFailedQueries = aBool;
}

/**
 * Connect automatically after awakeFromNib
 */
//@{
- (BOOL) connectsAutomatically
{
    return connectsAutomatically;
}

- (void) setConnectsAutomatically: (BOOL) aBool
{
    connectsAutomatically = aBool;
}
//@}

/**
 * Reset connection automatically
 */
//@{
- (BOOL) reconnectsAutomatically
{
    return reconnectsAutomatically;
}

- (void) setReconnectsAutomatically: (BOOL) aBool
{
    reconnectsAutomatically = aBool;
}
//@}

/**
 * Initial commands after making the connecting
 * \sa sendFinishedConnectingMessage:reconnect:
 */
//@{
- (NSString *) initialCommands
{
    return initialCommands;
}

- (void) setInitialCommands: (NSString *) aString
{
    if (aString != initialCommands)
    {
        [initialCommands release];
        initialCommands = [aString retain];
    }
}
//@}

/**
 * Information object related to the connected database
 */
//@{
/** \return the PGTSDatabaseInfo object, or nil if disconnected */
- (PGTSDatabaseInfo *) databaseInfo
{
    return databaseInfo;
}
/** Make a weak reference to the given object */
- (void) setDatabaseInfo: (PGTSDatabaseInfo *) anObject
{
    databaseInfo = anObject;
}
//@}

/**
 * The deserialization dictionary for result sets returned by this connection
 */
//@{
- (NSMutableDictionary *) deserializationDictionary
{
    return deserializationDictionary;
}

- (void) setDeserializationDictionary: (NSMutableDictionary *) aDictionary
{
    if (deserializationDictionary != aDictionary)
    {
        [deserializationDictionary release];
        deserializationDictionary = [aDictionary retain];
    }
}
//@}

/**
 * Connection timeout
 */
//@{
- (struct timeval) timeout
{
    return timeout;
}

- (void) setTimeout: (struct timeval) value
{
    timeout = value;
}
//@}

- (void) setLogsQueries: (BOOL) aBool
{
    logsQueries = aBool;
}

- (BOOL) logsQueries
{
    return logsQueries;
}

- (id <PGTSCertificateVerificationDelegate>) certificateVerificationDelegate
{
	return certificateVerificationDelegate;
}

- (void) setCertificateVerificationDelegate: (id <PGTSCertificateVerificationDelegate>) anObject
{
	certificateVerificationDelegate = anObject;
	if (nil == certificateVerificationDelegate)
		certificateVerificationDelegate = defaultCertDelegate;
}

- (BOOL) connectingAsync
{
	return (connecting && connectingAsync);
}
@end


/** 
 * Convenience methods for transaction handling
 * \return a BOOL indicating whether the query was successful
 */
@implementation PGTSConnection (TransactionHandling)
- (BOOL) beginTransaction
{
    return ((nil != [self executeQuery: @"BEGIN"]));
}

- (BOOL) commitTransaction
{
    return ((nil != [self executeQuery: @"COMMIT"]));
}

- (BOOL) rollbackTransaction
{
    return ((nil != [self executeQuery: @"ROLLBACK"]));
}

- (BOOL) rollbackToSavepointNamed: (NSString *) aName
{
    return ((nil != [self executeQuery: [NSString stringWithFormat: @"ROLLBACK TO SAVEPOINT %@", aName]]));
}

- (BOOL) savepointNamed: (NSString *) aName
{
    return ((nil != [self executeQuery: [NSString stringWithFormat: @"SAVEPOINT %@", aName]]));
}
@end


/** 
 * Connection status 
 */
@implementation PGTSConnection (StatusMethods)

- (BOOL) connected
{
	ConnStatusType status = [self connectionStatus];
    return (NULL != connection && CONNECTION_OK == status);
}

- (NSString *) databaseName
{
    return SafeStatusAccessor (&PQdb, connection);
}

- (NSString *) user
{
    return SafeStatusAccessor (&PQuser, connection);
}

- (NSString *) password
{
    return SafeStatusAccessor (&PQpass, connection);
}

- (NSString *) host
{
    return SafeStatusAccessor (&PQhost, connection);
}

- (long) port
{
    long rval = 0;
    char* portString = PQport (connection);
    if (NULL != portString)
        rval = strtol (portString, NULL, 10);
    return rval;
}

- (NSString *) commandLineOptions
{
    return SafeStatusAccessor (&PQoptions, connection);
}

- (ConnStatusType) connectionStatus
{
    return PQstatus (connection);
}

- (PGTransactionStatusType) transactionStatus
{
    return PQtransactionStatus (connection);
}

- (NSString *) statusOfParameter: (NSString *) parameterName
{
    NSString* rval = nil;
    if (nil != parameterName)
    {
        const char* value = PQparameterStatus (connection, 
                                               [parameterName UTF8String]);
        if (NULL != value)
            rval = [NSString stringWithUTF8String: value];
    }
    return rval;
}

- (int) protocolVersion
{
    return PQprotocolVersion (connection);
}

- (int) serverVersion
{
    return PQserverVersion (connection);
}

/**
 * The last error message.
 */
- (NSString *) errorMessage
{
    NSString* rval = nil;
    char* message = PQerrorMessage (connection);
    if (0 != strlen (message))
        rval = [NSString stringWithUTF8String: message];
	else
		rval = errorMessage;
	return rval;
}

- (int) backendPID
{
	return PQbackendPID (connection);
}

- (void *) sslStruct
{
#ifdef USE_SSL
	return PQgetssl (connection);
#else
    return NULL;
#endif
}

- (PGConnectionErrorCode) errorCode
{
	return PQerrorCode (connection);
}

@end


/** NSCoding implementation */
@implementation PGTSConnection (NSCoding)

- (id) initWithCoder: (NSCoder *) decoder
{
    if ((self = [super init]))
    {
        unsigned int returnedLength = 0;
        {
            //exceptionTable is set in setDelegate:
            
            connection = NULL;
            connectionLock = [[NSLock alloc] init];
            {
                timeout.tv_sec  = *[decoder decodeBytesForKey: @"timeout.tv_sec"  returnedLength: &returnedLength];
                if (sizeof (timeout.tv_sec) != returnedLength)
                    [[NSException exceptionWithName: NSInternalInconsistencyException reason: nil userInfo: nil] raise];
                timeout.tv_usec = *[decoder decodeBytesForKey: @"timeout.tv_usec" returnedLength: &returnedLength];
                if (sizeof (timeout.tv_usec) != returnedLength)
                    [[NSException exceptionWithName: NSInternalInconsistencyException reason: nil userInfo: nil] raise];
            }
            connectionString = [[decoder decodeObjectForKey: @"connectionString"] retain];
            connectionStatus = CONNECTION_BAD;
            messageDelegateAfterConnecting = YES;
            
            //socket               is set in workerThreadMain:
            asyncConnectionLock  = [[NSConditionLock alloc] initWithCondition: 0];
            workerThreadLock     = [[NSLock alloc] init];
            //shouldContinueThread is set in workerThreadMain:
            //threadRunning        is set in workerThreadMain:
            {
                id messenger       = [TSRunloopMessenger runLoopMessengerForCurrentRunLoop];            
                mainProxy          = [[messenger target: self withResult: NO]  retain];
                returningMainProxy = [[messenger target: self withResult: YES] retain];
            }
            //workerProxy          is set in workerThreadMain:
            //returningWorkerProxy is set in workerThreadMain:
            
            postgresNotificationCenter = [[NSNotificationCenter PGTSNotificationCenter] retain];
            notificationCounts = [[NSCountedSet alloc] init];
            notificationAssociations = [[NSMutableDictionary alloc] init];

            cancelRequest = NULL;
            //databaseInfo is set after the connection has been made
            parameterCounts = [MKCDictionary copyDictionaryWithKeyType: kMKCCollectionTypeObject
                                                             valueType: kMKCCollectionTypeInteger];
            deserializationDictionary = [decoder decodeObjectForKey: @"deserializationDictionary"];
            connectsAutomatically =  [decoder decodeBoolForKey: @"connectsAutomatically"];
            reconnectsAutomatically =  [decoder decodeBoolForKey: @"reconnectsAutomatically"];
            overlooksFailedQueries = [decoder decodeBoolForKey: @"overlooksFailedQueries"];
            delegateProcessesNotices = NO; //sic
            logsQueries = [decoder decodeBoolForKey: @"logQueries"];
            initialCommands = [[decoder decodeObjectForKey: @"initialCommands"] retain];
            {
                resultSetClass = NSClassFromString ([decoder decodeObjectForKey: @"resultSetClass"]);
                if (Nil == resultSetClass)
                    [[NSException exceptionWithName: NSInternalInconsistencyException reason: nil userInfo: nil] raise];
            }
            [self setDelegate: [decoder decodeObjectForKey: @"delegate"]];
        }
                
        {
            //Wait for the worker thread to start
            NSLock* threadStartLock = [[NSLock alloc] init];
            [threadStartLock lock];
            [NSThread detachNewThreadSelector: @selector (workerThreadMain:) toTarget: self withObject: threadStartLock];
            [threadStartLock lock];
            [threadStartLock unlock];
            [threadStartLock release];
            
            [[PGTSConnectionPool sharedInstance] addConnection: self];
        }
            
        if (connectsAutomatically)
            [self connect];
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder *) encoder
{
    //Operate on a disconnected copy to make reconnecting possible
    PGTSConnection* c = [self disconnectedCopy];
    {
        //exceptionTable is set in setDelegate:
        
        //connection     is reinitialized
        //connectionLock is reinitialized
        {
            [encoder encodeBytes: (const uint8_t *) &c->timeout.tv_sec  length: sizeof (c->timeout.tv_sec)  forKey: @"timeout.tv_sec"];
            [encoder encodeBytes: (const uint8_t *) &c->timeout.tv_usec length: sizeof (c->timeout.tv_usec) forKey: @"timeout.tv_usec"];        
        }
        [encoder encodeObject: c->connectionString forKey: @"connectionString"];
        //connectionStatus is reinitialized
        //messageDelegateAfterConnecting is reinitialized
        
        //socket               is set in workerThreadMain:
        //asyncConnectionLock  is reinitialized
        //workerThreadLock     is reinitialized
        //shouldContinueThread is set in workerThreadMain:
        //threadRunning        is set in workerThreadMain:
        //mainProxy            is reinitialized
        //returningMainProxy   is reinitialized
        //workerProxy          is set in workerThreadMain:
        //returningWorkerProxy is set in workerThreadMain:
        
        //postgresNotificationCenter is reinitialized
        //notificationCounts         is reinitialized
        //notificationAssociations   is reinitialized
        
        //cancelRequest   is reinitialized
        //databaseInfo    is reinitialized
        //parameterCounts is reinitialized
        [encoder encodeObject: c->deserializationDictionary forKey: @"deserializationDictionary"];
        [encoder encodeBool: c->connectsAutomatically forKey: @"connectsAutomatically"];
        [encoder encodeBool: c->reconnectsAutomatically forKey: @"reconnectsAutomatically"];
        [encoder encodeBool: c->overlooksFailedQueries forKey: @"overlooksFailedQueries"];
        //delegateProcessesNotices is reinitialized (sic)
        [encoder encodeBool: c->logsQueries forKey: @"logQueries"];
        [encoder encodeObject: c->initialCommands forKey: @"initialCommands"];
        [encoder encodeObject: NSStringFromClass (c->resultSetClass) forKey: @"resultSetClass"];
        [encoder encodeConditionalObject: c->delegate forKey: @"delegate"];
    }
    [c release];
}


@end
