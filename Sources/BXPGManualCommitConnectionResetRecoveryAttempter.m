//
// BXPGManualCommitConnectionResetRecoveryAttempter.m
// BaseTen
//
// Copyright 2008 Marko Karppinen & Co. LLC.
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
#import "BXPGManualCommitConnectionResetRecoveryAttempter.h"
#import "BXPGManualCommitTransactionHandler.h"
#import "BXLogger.h"


@implementation BXPGManualCommitConnectionResetRecoveryAttempter
- (void) dealloc
{
	[mSyncError release];
	[super dealloc];
}

- (BOOL) doAttemptRecoveryFromError: (NSError *) error outError: (NSError **) outError
{
	ExpectR (outError, NO);
	PGTSConnection* connection = [mHandler connection];
	PGTSConnection* notifyConnection = [(id) mHandler notifyConnection];
	
	[connection setDelegate: self];
	[notifyConnection setDelegate: self];

	[connection resetSync];
	[notifyConnection resetSync];
	
	//-finishedConnecting gets executed here.	
	
	if (! mSucceeded)
		*outError = mSyncError;
	
	return mSucceeded;
}


- (void) doAttemptRecoveryFromError: (NSError *) error
{
	mCounter = 2;
	mIsAsync = YES;
	
	PGTSConnection* connection = [mHandler connection];
	PGTSConnection* notifyConnection = [(id) mHandler notifyConnection];
	[connection setDelegate: self];
	[notifyConnection setDelegate: self];
	[connection resetAsync];
	[notifyConnection resetAsync];
}


- (void) finishedConnecting
{
	PGTSConnection* connection = [mHandler connection];
	PGTSConnection* notifyConnection = [(id) mHandler notifyConnection];
	
	ConnStatusType s1 = [connection connectionStatus];
	ConnStatusType s2 = [notifyConnection connectionStatus];
	mSucceeded = (CONNECTION_OK == s1 && CONNECTION_OK == s2);
	
	NSError* error1 = nil;
	NSError* error2 = nil;
	
	if (! mSucceeded)
	{
		error1 = [connection connectionError];
		error2 = [notifyConnection connectionError];
		mSyncError = [(error1 ?: error2) retain];
		
		[connection disconnect];
		[notifyConnection disconnect];
	}
	else
	{
		[connection setDelegate: mHandler];
		[notifyConnection setDelegate: mHandler];
	}
	
	if (mIsAsync)
	{
		[self attemptedRecovery: mSucceeded error: mSyncError];
		//FIXME: check modification tables?
		//FIXME: clear mHandlingConnectionLoss.
	}
}


- (void) waitForConnection
{
	//Wait until both connections have finished.
	mCounter--;
	if (! mCounter)
		[self finishedConnecting];
}


- (void) PGTSConnectionFailed: (PGTSConnection *) connection
{
	[self waitForConnection];
}


- (void) PGTSConnectionEstablished: (PGTSConnection *) connection
{
	[self waitForConnection];
}
@end
