//
// PGTSConnector.m
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


#import "PGTSConnector.h"
#import "PGTSConstants.h"
#import "PGTSConnection.h"
#import "BXLogger.h"
#import "BXError.h"
#import "NSString+PGTSAdditions.h"
#import "libpq_additions.h"


char*
PGTSCopyConnectionString (NSDictionary* connectionDict)
{
	NSMutableString* connectionString = [NSMutableString string];
	NSEnumerator* e = [connectionDict keyEnumerator];
	NSString* currentKey;
	NSString* format = @"%@ = '%@' ";
	while ((currentKey = [e nextObject]))
	{
		if ([kPGTSConnectionDictionaryKeys containsObject: currentKey])
			[connectionString appendFormat: format, currentKey, [connectionDict objectForKey: currentKey]];
	}
	char* retval = strdup ([connectionString UTF8String]);

	//For GC.
	[connectionString self];
	return retval;
}


#ifdef USE_SSL
#import <openssl/ssl.h>
//This is thread safe because it's called in +initialize for the first time.
//Afterwards, the static variable is only read.
static int
SSLConnectionExIndex ()
{
	static volatile int sslConnectionExIndex = -1;
    if (-1 == sslConnectionExIndex) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		sslConnectionExIndex = SSL_get_ex_new_index (0, NULL, NULL, NULL, NULL);
#pragma clang diagnostic pop
    }
	return sslConnectionExIndex;
}


/**
 * \internal
 * \brief Verify an X.509 certificate.
 */
static int
VerifySSLCertificate (int preverify_ok, X509_STORE_CTX *x509_ctx)
{
	int retval = 0;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	SSL* ssl = X509_STORE_CTX_get_ex_data (x509_ctx, SSL_get_ex_data_X509_STORE_CTX_idx ());
	PGTSConnector* connector = SSL_get_ex_data (ssl, SSLConnectionExIndex ());
#pragma clang diagnostic pop
	id <PGTSConnectorDelegate> delegate = [connector delegate];

	if ([delegate allowSSLForConnector: connector context: x509_ctx preverifyStatus: preverify_ok])
		retval = 1;
	else 
	{
		retval = 0;
		[connector setServerCertificateVerificationFailed: YES];
	}
	return retval;
}
#endif


@implementation PGTSConnector
+ (void) initialize
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
#ifdef USE_SSL
		SSLConnectionExIndex ();
#endif
	}
}


- (id) init
{
    if ((self = [super init]))
    {
        mPollFunction = &PQconnectPoll;
    }
    return self;
}


- (void) dealloc
{
	//Everything is weak.
	[super dealloc];
}


- (BOOL) SSLSetUp
{
	return mSSLSetUp;
}


- (id <PGTSConnectorDelegate>) delegate
{
	return mDelegate;
}


- (void) setDelegate: (id <PGTSConnectorDelegate>) anObject
{
	mDelegate = anObject;
}


- (BOOL) connect: (NSDictionary *) connectionDictionary
{
	return NO;
}


- (void) cancel
{
}


- (BOOL) start: (const char *) connectionString
{
	if (mConnection)
		PQfinish (mConnection);
	
	mConnection = PQconnectStart (connectionString);
	return (mConnection ? YES : NO);
}


- (void) setConnection: (PGconn *) connection
{
	mConnection = connection;
}


- (void) setTraceFile: (FILE *) stream
{
	mTraceFile = stream;
}


- (void) setServerCertificateVerificationFailed: (BOOL) aBool
{
	mServerCertificateVerificationFailed = aBool;
}


- (NSError *) connectionError
{
	return [[mConnectionError copy] autorelease];
}


- (void) setConnectionError: (NSError *) anError
{
	if (anError != mConnectionError)
	{
		[mConnectionError release];
		mConnectionError = [anError retain];
	}
}


- (void) finishedConnecting: (BOOL) status
{
	BXLogDebug (@"Finished connecting (%d).", status);
	
	if (status)
	{
		//Resign ownership. mConnection needs to be set to NULL before calling delegate method.
		PGconn* connection = mConnection;
		mConnection = NULL;
		[mDelegate connector: self gotConnection: connection];
	}
	else
	{
		if (! mConnectionError)
		{
			enum PGTSConnectionError code = kPGTSConnectionErrorNone;
			const char* SSLMode = pq_ssl_mode (mConnection);
			
			if (! mNegotiationStarted)
				code = kPGTSConnectionErrorUnknown;
			else if (0 == strcmp ("require", SSLMode))
			{
				if (mServerCertificateVerificationFailed)
					code = kPGTSConnectionErrorSSLCertificateVerificationFailed;
				else if (mSSLSetUp)
					code = kPGTSConnectionErrorSSLError;
				else
					code = kPGTSConnectionErrorSSLUnavailable;
			}
			else if (PQconnectionNeedsPassword (mConnection))
				code = kPGTSConnectionErrorPasswordRequired;
			else if (PQconnectionUsedPassword (mConnection))
				code = kPGTSConnectionErrorInvalidPassword;
			else
				code = kPGTSConnectionErrorUnknown;
			
			NSString* errorTitle = NSLocalizedStringWithDefaultValue (@"connectionError", nil, [NSBundle bundleForClass: [self class]],
																	  @"Connection error", @"Title for a sheet.");
			NSString* message = [NSString stringWithUTF8String: PQerrorMessage (mConnection)];
			message = PGTSReformatErrorMessage (message);
			NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									  errorTitle, NSLocalizedDescriptionKey,
									  errorTitle, NSLocalizedFailureReasonErrorKey,
									  message, NSLocalizedRecoverySuggestionErrorKey,
									  nil];
			
			//FIXME: error code
			NSError* error = [BXError errorWithDomain: kPGTSConnectionErrorDomain code: code userInfo: userInfo];
			[self setConnectionError: error];
		}	
		
		PQfinish (mConnection);		
		mConnection = NULL;
		[mDelegate connectorFailed: self];		
	}	
}


- (void)setUpSSL {
#ifdef USE_SSL
	ConnStatusType status = PQstatus (mConnection);
	if (! mSSLSetUp && CONNECTION_SSL_CONTINUE == status) {
		mSSLSetUp = YES;
		SSL* ssl = PQgetssl (mConnection);
		BXAssertVoidReturn (ssl, @"Expected ssl struct not to be NULL.");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		SSL_set_verify (ssl, SSL_VERIFY_PEER, &VerifySSLCertificate);
		SSL_set_ex_data (ssl, SSLConnectionExIndex (), self);
#pragma clang diagnostic pop
	}
#endif
}


- (void) prepareToConnect
{
	mSSLSetUp = NO;
	mNegotiationStarted = NO;
	mServerCertificateVerificationFailed = NO;
	[self setConnectionError: nil];
}
@end
