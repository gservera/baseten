//
// PGTSConstants.h
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

#import <Foundation/Foundation.h>
#import <BaseTen/BXExport.h>

// Some of the following symbols are used in the unit tests,
// which is why they have been exported.


#define kPGTSPUBLICOid InvalidOid


BX_INTERNAL NSDictionary* kPGTSDefaultConnectionDictionary;

BX_EXPORT   NSString* const kPGTSHostKey;
BX_INTERNAL NSString* const kPGTSHostAddressKey;
BX_INTERNAL NSString* const kPGTSPortKey;
BX_EXPORT   NSString* const kPGTSDatabaseNameKey;
BX_EXPORT   NSString* const kPGTSUserNameKey;
BX_INTERNAL NSString* const kPGTSPasswordKey;
BX_INTERNAL NSString* const kPGTSConnectTimeoutKey;
BX_INTERNAL NSString* const kPGTSOptionsKey;
BX_EXPORT   NSString* const kPGTSSSLModeKey;
BX_INTERNAL NSString* const kPGTSServiceNameKey;
BX_INTERNAL NSArray* kPGTSConnectionDictionaryKeys;

BX_INTERNAL NSString* const kPGTSRetrievedResultNotification;
BX_INTERNAL NSString* const kPGTSBackendPIDKey;
BX_INTERNAL NSString* const kPGTSNotificationNameKey;
BX_INTERNAL NSString* const kPGTSNotificationExtraKey;
BX_INTERNAL NSString* const kPGTSWillDisconnectNotification;
BX_INTERNAL NSString* const kPGTSDidDisconnectNotification;
BX_INTERNAL NSString* const kPGTSNotice;
BX_INTERNAL NSString* const kPGTSNoticeMessageKey;
BX_INTERNAL NSString* const kPGTSConnectionPoolItemDidRemoveConnectionNotification;
BX_INTERNAL NSString* const kPGTSConnectionPoolItemDidAddConnectionNotification;
BX_INTERNAL NSString* const kPGTSRowKey;
BX_INTERNAL NSString* const kPGTSRowsKey;
BX_INTERNAL NSString* const kPGTSTableKey;

BX_INTERNAL NSString* const kPGTSConnectionKey;
BX_INTERNAL NSString* const kPGTSConnectionDelegateKey;

BX_INTERNAL NSString* const kPGTSFieldnameKey;
BX_INTERNAL NSString* const kPGTSFieldKey;
BX_INTERNAL NSString* const kPGTSValueKey;
BX_INTERNAL NSString* const kPGTSRowIndexKey;
BX_INTERNAL NSString* const kPGTSResultSetKey;
BX_INTERNAL NSString* const kPGTSDataSourceKey;

BX_INTERNAL NSString* const kPGTSNoKeyFieldsException;
BX_INTERNAL NSString* const kPGTSNoKeyFieldException;
BX_INTERNAL NSString* const kPGTSFieldNotFoundException;
BX_INTERNAL NSString* const kPGTSNoPrimaryKeyException;
BX_INTERNAL NSString* const kPGTSQueryFailedException;
BX_INTERNAL NSString* const kPGTSConnectionFailedException;

BX_INTERNAL NSString* const kPGTSModificationNameKey;
BX_INTERNAL NSString* const kPGTSInsertModification;
BX_INTERNAL NSString* const kPGTSUpdateModification;
BX_INTERNAL NSString* const kPGTSDeleteModification;

BX_INTERNAL NSString* const kPGTSLockedForUpdate;
BX_INTERNAL NSString* const kPGTSLockedForDelete;
BX_INTERNAL NSString* const kPGTSUnlockedRowsNotification;
BX_INTERNAL NSString* const kPGTSRowShareLock;

BX_INTERNAL NSString* const kPGTSUnsupportedPredicateOperatorTypeException;
BX_INTERNAL NSString* const kPGTSParametersKey;
BX_INTERNAL NSString* const kPGTSParameterIndexKey;
BX_INTERNAL NSString* const kPGTSExpressionParametersVerbatimKey;

BX_INTERNAL NSString* const kPGTSErrorSeverity;
BX_INTERNAL NSString* const kPGTSErrorSQLState;
BX_EXPORT   NSString* const kPGTSErrorPrimaryMessage;
BX_INTERNAL NSString* const kPGTSErrorDetailMessage;
BX_INTERNAL NSString* const kPGTSErrorHint;
BX_INTERNAL NSString* const kPGTSErrorInternalQuery;
BX_INTERNAL NSString* const kPGTSErrorContext;
BX_INTERNAL NSString* const kPGTSErrorSourceFile;
BX_INTERNAL NSString* const kPGTSErrorSourceFunction;
BX_INTERNAL NSString* const kPGTSErrorStatementPosition;
BX_INTERNAL NSString* const kPGTSErrorInternalPosition;
BX_INTERNAL NSString* const kPGTSErrorSourceLine;
BX_INTERNAL NSString* const kPGTSErrorMessage;
BX_INTERNAL NSString* const kPGTSSSLAttemptedKey;
    

BX_INTERNAL NSString* const kPGTSErrorDomain;
BX_INTERNAL NSString* const kPGTSConnectionErrorDomain;
enum PGTSErrors
{
    kPGTSUnsuccessfulQueryError = 1
};
/* See PGTSConnectionDelegate.h */

enum PGTSACLItemPrivilege
{
    kPGTSPrivilegeNone            = 0,
	//1 << 0 missing
    kPGTSPrivilegeSelect          = 1 << 1,
    kPGTSPrivilegeSelectGrant     = 1 << 2,
    kPGTSPrivilegeUpdate          = 1 << 3,
    kPGTSPrivilegeUpdateGrant     = 1 << 4,
    kPGTSPrivilegeInsert          = 1 << 5,
    kPGTSPrivilegeInsertGrant     = 1 << 6,
    kPGTSPrivilegeDelete          = 1 << 7,
    kPGTSPrivilegeDeleteGrant     = 1 << 8,
    kPGTSPrivilegeReferences      = 1 << 9,
    kPGTSPrivilegeReferencesGrant = 1 << 10,
    kPGTSPrivilegeTrigger         = 1 << 11,
    kPGTSPrivilegeTriggerGrant    = 1 << 12,
    kPGTSPrivilegeExecute         = 1 << 13,
    kPGTSPrivilegeExecuteGrant    = 1 << 14,
    kPGTSPrivilegeUsage           = 1 << 15,
    kPGTSPrivilegeUsageGrant      = 1 << 16,
    kPGTSPrivilegeCreate          = 1 << 17,
    kPGTSPrivilegeCreateGrant     = 1 << 18,
    kPGTSPrivilegeConnect         = 1 << 19,
    kPGTSPrivilegeConnectGrant    = 1 << 20,
    kPGTSPrivilegeTemporary       = 1 << 21,
    kPGTSPrivilegeTemporaryGrant  = 1 << 22
};

enum PGTSDeleteRule
{
	kPGTSDeleteRuleUnknown		  = 0,
	kPGTSDeleteRuleNone,
	kPGTSDeleteRuleNoAction,
	kPGTSDeleteRuleRestrict,
	kPGTSDeleteRuleCascade,
	kPGTSDeleteRuleSetNull,
	kPGTSDeleteRuleSetDefault
};
