//
// BXPGReconnectionRecoveryAttempter.m
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

#import "BXPGReconnectionRecoveryAttempter.h"
#import "BXPGTransactionHandler.h"
#import "BXLogger.h"


@implementation BXPGReconnectionRecoveryAttempter
- (BOOL) doAttemptRecoveryFromError: (NSError *) error outError: (NSError **) outError
{
	ExpectR (outError, NO);
	return [[[mHandler interface] databaseContext] connectSync: outError];
}


- (void) doAttemptRecoveryFromError: (NSError *) error
{
	PGTSConnection* connection = [mHandler connection];
	[connection setDelegate: self];
	[[[mHandler interface] databaseContext] connectAsync];
}

- (void) PGTSConnectionFailed: (PGTSConnection *) connection
{
	[connection setDelegate: mHandler];
	NSError* error = [connection connectionError];
	[connection disconnect];
	[self attemptedRecovery: NO error: error];
}


- (void) PGTSConnectionEstablished: (PGTSConnection *) connection
{
	[connection setDelegate: mHandler];
	[self attemptedRecovery: YES error: nil];
	
	//FIXME: check modification tables?
}
@end
