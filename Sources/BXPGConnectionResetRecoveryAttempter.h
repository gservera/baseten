//
// BXPGConnectionResetRecoveryAttempter.h
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

#import <Foundation/Foundation.h>
#import "PGTS.h"
#import "BaseTen.h"
@class BXPGTransactionHandler;


@interface BXPGConnectionRecoveryAttempter : NSObject
{
@public
	BXPGTransactionHandler* mHandler;
	
@protected
	NSInvocation* mRecoveryInvocation;
}
- (void) setRecoveryInvocation: (NSInvocation *) anInvocation;
- (NSInvocation *) recoveryInvocation: (id) target selector: (SEL) selector contextInfo: (void *) contextInfo;

- (BOOL) attemptRecoveryFromError: (NSError *) error optionIndex: (NSUInteger) recoveryOptionIndex;
- (void) attemptRecoveryFromError: (NSError *) error optionIndex: (NSUInteger) recoveryOptionIndex 
						 delegate: (id) delegate didRecoverSelector: (SEL) didRecoverSelector contextInfo: (void *) contextInfo;
- (void) allowConnecting: (BOOL) allow;

//Used with the synchronous method.
- (BOOL) doAttemptRecoveryFromError: (NSError *) error outError: (NSError **) error;
//Used with the asynchronous method.
- (void) doAttemptRecoveryFromError: (NSError *) error;
- (void) attemptedRecovery: (BOOL) succeeded error: (NSError *) newError;
@end


@interface BXPGConnectionRecoveryAttempter (PGTSConnectionDelegate) <PGTSConnectionDelegate>
@end
