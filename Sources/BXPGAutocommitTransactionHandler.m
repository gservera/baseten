//
// BXPGAutocommitTransactionHandler.m
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

#import "BXPGInterface.h"
#import "BXPGAutocommitTransactionHandler.h"
#import "BXPGAutocommitConnectionResetRecoveryAttempter.h"
#import "BXPGReconnectionRecoveryAttempter.h"
#import "BXPGAdditions.h"
#import "BXProbes.h"
#import "BXLogger.h"


@implementation BXPGAutocommitTransactionHandler
- (void) markLocked: (BXEntityDescription *) entity 
	  relationAlias: (NSString *) alias
		 fromClause: (NSString *) fromClause
		whereClause: (NSString *) whereClause 
		 parameters: (NSArray *) parameters
		 willDelete: (BOOL) willDelete
{
	[self markLocked: entity 
	   relationAlias: alias
		  fromClause: fromClause
		 whereClause: whereClause 
		  parameters: parameters
		  willDelete: willDelete
		  connection: mConnection 
	notifyConnection: mConnection];
}
@end


@implementation BXPGAutocommitTransactionHandler (Observing)
- (BOOL) observeEntity: (BXEntityDescription *) entity options: (enum BXObservingOption) options error: (NSError **) error
{
	return [self observeEntity: entity connection: mConnection options: options error: error];
}

- (void) checkSuperEntities: (BXEntityDescription *) entity
{
	[self checkSuperEntities: entity connection: mConnection];
}
@end


@implementation BXPGAutocommitTransactionHandler (Connecting)
- (void) connectAsync
{
	[self prepareForConnecting];
	mAsync = YES;
	
	NSDictionary* connectionDictionary = [self connectionDictionary];
	[mConnection connectAsync: connectionDictionary];
}


- (BOOL) connectSync: (NSError **) outError
{
	ExpectR (outError, NO);
	
	[self prepareForConnecting];
	mAsync = NO;
	mSyncErrorPtr = outError;
	
	NSDictionary* connectionDictionary = [self connectionDictionary];
	[mConnection connectSync: connectionDictionary];
	
	//-finishedConnecting gets executed here.
	
	mSyncErrorPtr = NULL;
	return mConnectionSucceeded;
}


- (void) PGTSConnectionFailed: (PGTSConnection *) connection
{
	[self handleConnectionErrorFor: connection];
}


- (void) PGTSConnectionEstablished: (PGTSConnection *) connection
{
	[self handleSuccess];
}


- (void) PGTSConnectionLost: (PGTSConnection *) connection error: (NSError *) error
{
	[self didDisconnect];
	
	Class attempterClass = Nil;
	if ([connection pgConnection])
		attempterClass = [BXPGAutocommitConnectionResetRecoveryAttempter class];
	else
		attempterClass = [BXPGReconnectionRecoveryAttempter class];

	error = [self connectionError: error recoveryAttempterClass: attempterClass];
	[mInterface connectionLost: self error: error];
}
@end


@implementation BXPGAutocommitTransactionHandler (Transactions)
- (BOOL) savepointIfNeeded: (NSError **) outError
{
	return YES;
}


- (BOOL) beginSubTransactionIfNeeded: (NSError **) outError
{
	return [self beginIfNeeded: outError];
}


- (void) beginAsyncSubTransactionFor: (id) delegate callback: (SEL) callback userInfo: (NSDictionary *) userInfo
{
	[self beginIfNeededFor: delegate callback: callback userInfo: userInfo];
}


- (BOOL) endSubtransactionIfNeeded: (NSError **) outError
{
	return [self save: outError];
}


- (void) rollbackSubtransaction
{
	//FIXME: consider whether we need an error pointer here or just assert that the query succeeds.
	NSError* localError = nil;
	[self rollback: &localError];
	BXAssertLog (! localError, @"Expected rollback to savepoint succeed. Error: %@", localError);
}


- (BOOL) autocommits
{
	return YES;
}
@end
