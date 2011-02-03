//
// PGTSConnector.h
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

#import <Foundation/Foundation.h>
#import <BaseTen/BXExport.h>
#import <BaseTen/postgresql/libpq-fe.h>

@class PGTSConnector;


BX_INTERNAL char *PGTSCopyConnectionString (NSDictionary *);


@protocol PGTSConnectorDelegate <NSObject>
- (void) connector: (PGTSConnector *) connector gotConnection: (PGconn *) connection;
- (void) connectorFailed: (PGTSConnector *) connector;
- (BOOL) allowSSLForConnector: (PGTSConnector *) connector context: (void *) x509_ctx preverifyStatus: (int) preverifyStatus;
@end


@interface PGTSConnector : NSObject
{
	id <PGTSConnectorDelegate> mDelegate; //Weak
	PostgresPollingStatusType (* mPollFunction)(PGconn *);
	PGconn* mConnection;
	NSError* mConnectionError;
	FILE* mTraceFile;
	BOOL mSSLSetUp;
	BOOL mNegotiationStarted;
	BOOL mServerCertificateVerificationFailed;
}
- (BOOL) connect: (NSDictionary *) connectionDictionary;
- (void) cancel;
- (id <PGTSConnectorDelegate>) delegate;
- (void) setDelegate: (id <PGTSConnectorDelegate>) anObject;
- (void) setConnection: (PGconn *) connection;
- (void) setServerCertificateVerificationFailed: (BOOL) aBool;

- (BOOL) start: (const char *) connectionString;
- (void) setTraceFile: (FILE *) stream;

- (NSError *) connectionError;
- (void) setConnectionError: (NSError *) anError;

- (void) finishedConnecting: (BOOL) status;
- (void) setUpSSL;
- (void) prepareToConnect;
@end
