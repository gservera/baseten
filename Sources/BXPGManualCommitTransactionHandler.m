//
// BXPGManualCommitTransactionHandler.m
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

#import "PGTSConnection.h"
#import "BXPGInterface.h"
#import "BXPGCertificateVerificationDelegate.h"
#import "BXPGManualCommitTransactionHandler.h"
#import "BXPGManualCommitConnectionResetRecoveryAttempter.h"
#import "BXPGReconnectionRecoveryAttempter.h"
#import "BXPGAdditions.h"
#import "BXProbes.h"
#import "BXLogger.h"


@implementation BXPGManualCommitTransactionHandler
- (void) setLogsQueries: (BOOL) shouldLog
{
	[super setLogsQueries: shouldLog];
	[mNotifyConnection setLogsQueries: shouldLog];
}


- (BXPGDatabaseDescription *) databaseDescription
{
	return (id) [mNotifyConnection databaseDescription];
}


- (PGTSConnection *) notifyConnection
{
	return mNotifyConnection;
}


- (BOOL) isSSLInUse
{
	return ([super isSSLInUse] && [mNotifyConnection SSLStruct] ? YES : NO);
}


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
	notifyConnection: mNotifyConnection];
}


- (void) savepointFor: (id) delegate callback: (SEL) callback userInfo: (id) userInfo
{
    NSDictionary* newUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                 NSStringFromSelector (callback), kBXPGCallbackSelectorStringKey,
                                 delegate, kBXPGDelegateKey,
                                 userInfo, kBXPGUserInfoKey,
                                 nil];
    [self beginIfNeededFor: self callback: @selector (begunTransaction:) userInfo: newUserInfo];
}


- (BOOL) savepointIfNeeded: (NSError **) outError
{
	ExpectR (outError, NO);
	BOOL retval = NO;
	if ((retval = [self beginIfNeeded: outError]))
	{
		PGTransactionStatusType status = [mConnection transactionStatus];
		if (PQTRANS_INTRANS == status)
		{
			NSString* query = [self savepointQuery];
			PGTSResultSet* res = [mConnection executeQuery: query];
			if ([res querySucceeded])
				retval = YES;
			else
				*outError = [res error];
		}
		else
		{
			retval = NO;
			//FIXME: handle the error.
			BXLogError (@"Transaction status had a strange value: %d", status);
		}
	}
	return retval;
}


- (void) begunTransaction: (id <BXPGResultSetPlaceholder>) placeholderResult
{
	if ([placeholderResult querySucceeded])
	{
		[mConnection sendQuery: [self savepointQuery] delegate: self callback: @selector (createdSavepoint:)
				parameterArray: nil userInfo: [placeholderResult userInfo]];
	}
	else
	{
		[self forwardResult: placeholderResult];
	}
}


- (void) createdSavepoint: (PGTSResultSet *) res
{
	[self forwardResult: res];
}


- (void) reloadDatabaseMetadata
{
	[super reloadDatabaseMetadata];
	[mNotifyConnection reloadDatabaseDescription];
}
@end


@implementation BXPGManualCommitTransactionHandler (Observing)
- (BOOL) observeEntity: (BXEntityDescription *) entity options: (enum BXObservingOption) options error: (NSError **) error
{
	return [self observeEntity: entity connection: mNotifyConnection options: options error: error];
}

- (void) checkSuperEntities: (BXEntityDescription *) entity
{
	[self checkSuperEntities: entity connection: mNotifyConnection];
}
@end


@implementation BXPGManualCommitTransactionHandler (Connecting)
- (BOOL) connected
{
	return (CONNECTION_OK == [mConnection connectionStatus] &&
			CONNECTION_OK == [mNotifyConnection connectionStatus]);
}

- (void) disconnect
{
	[mNotifyConnection executeQuery: @"SELECT baseten.lock_unlock ()"];
	[mNotifyConnection disconnect];
	[mNotifyConnection setDelegate: nil];
	[mNotifyConnection release];
	mNotifyConnection = nil;

	[super disconnect];
}


- (void) prepareForConnecting
{
	mCounter = 2;
	
	[super prepareForConnecting];
	
	if (! mNotifyConnection)
	{
		mNotifyConnection = [[PGTSConnection alloc] init];
		[mNotifyConnection setDelegate: self];
		[mNotifyConnection setLogsQueries: [mInterface logsQueries]];
		[mNotifyConnection setCertificateVerificationDelegate: mCertificateVerificationDelegate];
	}
}

- (void) connectAsync
{	
	[self prepareForConnecting];
	mAsync = YES;
	
	NSDictionary* connectionDictionary = [self connectionDictionary];
	BXLogDebug (@"Making main connection connect.");
	[mConnection connectAsync: connectionDictionary];
	BXLogDebug (@"Making notification connection connect.");
	[mNotifyConnection connectAsync: connectionDictionary];
}


- (BOOL) connectSync: (NSError **) outError
{
	ExpectR (outError, NO);
	
	[self prepareForConnecting];
	mAsync = NO;
	mSyncErrorPtr = outError;
	
	NSDictionary* connectionDictionary = [self connectionDictionary];
	[mConnection connectSync: connectionDictionary];
	[mNotifyConnection connectSync: connectionDictionary];
	
	//-finishedConnecting gets executed here.
	
	mSyncErrorPtr = NULL;
	return mConnectionSucceeded;
}


- (void) finishedConnecting
{
	mCounter = 2; //For connection loss.
	
	//For simplicity, we only return one error. The error would probably be
	//the same for both connections anyway (e.g. invalid certificate, wrong password, etc.).
	PGTSConnection* failedConnection = nil;
	if (CONNECTION_BAD == [mConnection connectionStatus])
		failedConnection = mConnection;
	else if (CONNECTION_BAD == [mNotifyConnection connectionStatus])
		failedConnection = mNotifyConnection;
	
	if (failedConnection)
		[self handleConnectionErrorFor: failedConnection];
	else
		[self handleSuccess];
}


- (void) waitForConnection
{
	//Wait until both connections have finished.
	mCounter--;
	if (! mCounter)
		[self finishedConnecting];
}


- (void) handleSuccess
{
	[super handleSuccess];
	BXLogDebug (@"mNotifyConnection: %p", mNotifyConnection);
}


- (void) PGTSConnectionFailed: (PGTSConnection *) connection
{
	[self waitForConnection];
}


- (void) PGTSConnectionEstablished: (PGTSConnection *) connection
{
	[self waitForConnection];
}


- (void) PGTSConnectionLost: (PGTSConnection *) connection error: (NSError *) error
{
	if (! mHandlingConnectionLoss)
	{
		mHandlingConnectionLoss = YES;
		[self didDisconnect];

		Class attempterClass = Nil;
		if ([mConnection pgConnection] && [mNotifyConnection pgConnection])
			attempterClass = [BXPGManualCommitConnectionResetRecoveryAttempter class];
		else
			attempterClass = [BXPGReconnectionRecoveryAttempter class];

		error = [self connectionError: error recoveryAttempterClass: attempterClass];
		[mInterface connectionLost: self error: error];
	}
}

- (BOOL) usedPassword
{
	return [super usedPassword] || [mNotifyConnection usedPassword];
}
@end



@implementation BXPGManualCommitTransactionHandler (Transactions)
- (BOOL) rollbackToLastSavepoint: (NSError **) outError
{
	ExpectR (outError, NO);
	
	BOOL retval = NO;
	PGTransactionStatusType status = [mConnection transactionStatus];
	if (PQTRANS_IDLE != status)
	{
		NSString* query = [self rollbackToSavepointQuery];
		PGTSResultSet* res = [mConnection executeQuery: query];
		
		if (BASETEN_SENT_ROLLBACK_TO_SAVEPOINT_ENABLED ())
		{
			char* message_s = strdup ([query UTF8String]);
			BASETEN_SENT_ROLLBACK_TO_SAVEPOINT (mConnection, [res status], message_s);
			free (message_s);			
		}
		
		if ([res querySucceeded])
			retval = YES;
		else
			*outError = [res error];
	}
	else 
	{
		//FIXME: set the error.
		BXLogError (@"Transaction status had a strange value: %d", status);
	}
	return retval;
}


- (BOOL) beginSubTransactionIfNeeded: (NSError **) outError
{
	return [self savepointIfNeeded: outError];
}


- (void) beginAsyncSubTransactionFor: (id) delegate callback: (SEL) callback userInfo: (NSDictionary *) userInfo
{
	[self savepointFor: delegate callback: callback userInfo: userInfo];
}


- (BOOL) endSubtransactionIfNeeded: (NSError **) outError
{
	return YES;
}


- (void) rollbackSubtransaction
{
	//FIXME: consider whether we need an error pointer here or just assert that the query succeeds.
	NSError* localError = nil;
	[self rollbackToLastSavepoint: &localError];
	BXAssertLog (! localError, @"Expected rollback to savepoint succeed. Error: %@", localError);
}


- (BOOL) autocommits
{
	return NO;
}
@end
