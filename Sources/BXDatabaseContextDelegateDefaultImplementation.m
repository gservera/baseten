//
// BXDatabaseContextDelegateDefaultImplementation.m
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

#import "BXDatabaseContext.h"
#import "BXDatabaseContextDelegateDefaultImplementation.h"
#import "BXException.h"
#import "BXLogger.h"

#if (TARGET_OS_MAC)
#import <AppKit/AppKit.h>
#else
static id NSApp = nil;
#endif



@implementation BXDatabaseContextDelegateDefaultImplementation
- (void) databaseContext: (BXDatabaseContext *) context 
				hadError: (NSError *) error 
		  willBePassedOn: (BOOL) willBePassedOn
{
	if (! willBePassedOn)
		@throw [error BXExceptionWithName: kBXExceptionUnhandledError];
}

- (void) databaseContext: (BXDatabaseContext *) context
	hadReconnectionError: (NSError *) error
{
	if (NULL != NSApp)
		[NSApp presentError: error];
	else
		BXLogError (@"Error while trying to reconnect: %@ (userInfo: %@).", error, [error userInfo]);
}

- (void) databaseContext: (BXDatabaseContext *) context lostConnection: (NSError *) error
{
	if (NULL != NSApp)
	{
		//FIXME: do something about this; not just logging.
		if ([NSApp presentError: error])
			BXLogInfo (@"Reconnected.");
		else
		{
			BXLogInfo (@"Failed to reconnect.");
			[context setAllowReconnecting: NO];
		}
	}
	else
	{
		@throw [error BXExceptionWithName: kBXExceptionUnhandledError];
	}
}

- (enum BXCertificatePolicy) databaseContext: (BXDatabaseContext *) ctx 
						  handleInvalidTrust: (SecTrustRef) trust 
									  result: (SecTrustResultType) result
{
	enum BXCertificatePolicy policy = kBXCertificatePolicyDeny;
	if (NULL != NSApp)
		policy = kBXCertificatePolicyDisplayTrustPanel;
	return policy;
}

- (enum BXSSLMode) SSLModeForDatabaseContext: (BXDatabaseContext *) ctx
{
	return kBXSSLModePrefer;
}
@end
