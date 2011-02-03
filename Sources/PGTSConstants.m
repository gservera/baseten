//
// PGTSConstants.m
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

#import <Foundation/Foundation.h>
#import "PGTSConstants.h"


__strong NSDictionary* kPGTSDefaultConnectionDictionary    = nil;
__strong NSArray* kPGTSConnectionDictionaryKeys            = nil;

NSString* const kPGTSHostKey                      = @"host";
NSString* const kPGTSHostAddressKey               = @"hostaddr";
NSString* const kPGTSPortKey                      = @"port";
NSString* const kPGTSDatabaseNameKey              = @"dbname";
NSString* const kPGTSUserNameKey                  = @"user";
NSString* const kPGTSPasswordKey                  = @"password";
NSString* const kPGTSConnectTimeoutKey            = @"connect_timeout";
NSString* const kPGTSOptionsKey                   = @"options";
NSString* const kPGTSSSLModeKey                   = @"sslmode";
NSString* const kPGTSServiceNameKey               = @"service"; 

NSString* const kPGTSRetrievedResultNotification  = @"kPGTSRetrievedResultNotification";
NSString* const kPGTSNotificationNameKey		  = @"kPGTSNotificationNameKey";
NSString* const kPGTSBackendPIDKey    = @"Backend PID";
NSString* const kPGTSNotificationExtraKey         = @"Extra parameters";
NSString* const kPGTSWillDisconnectNotification   = @"kPGTSWillDisconnectNotification";
NSString* const kPGTSDidDisconnectNotification    = @"kPGTSDidDisconnectNotification";
NSString* const kPGTSNotice                       = @"kPGTSNotice";
NSString* const kPGTSNoticeMessageKey             = @"kPGTSNoticeMessageKey";
NSString* const kPGTSConnectionPoolItemDidRemoveConnectionNotification = 
    @"kPGTSConnectionPoolItemWillRemoveConnectionNotification";
NSString* const kPGTSConnectionPoolItemDidAddConnectionNotification =
    @"kPGTSConnectionPoolItemDidAddConnectionNotification";
NSString* const kPGTSRowKey                       = @"kPGTSRowsKey";
NSString* const kPGTSRowsKey                      = @"kPGTSRowsKey";
NSString* const kPGTSTableKey                     = @"kPGTSTableKey";

NSString* const kPGTSConnectionKey                = @"kPGTSConnectionKey";
NSString* const kPGTSConnectionDelegateKey        = @"kPGTSConnectionDelegateKey";

NSString* const kPGTSFieldnameKey                 = @"kPGTSFieldnameKey";
NSString* const kPGTSFieldKey                     = @"kPGTSFieldKey";
NSString* const kPGTSKeyFieldKey                  = @"kPGTSKeyFieldKey";
NSString* const kPGTSValueKey                     = @"kPGTSValueKey";
NSString* const kPGTSRowIndexKey                  = @"kPGTSRowIndexKey";
NSString* const kPGTSResultSetKey                 = @"kPGTSResultSetKey";
NSString* const kPGTSDataSourceKey                = @"kPGTSDataSourceKey";

NSString* const kPGTSNoKeyFieldsException         = @"kPGTSNoKeyFieldsException";
NSString* const kPGTSNoKeyFieldException          = @"kPGTSNoKeyFieldException";
NSString* const kPGTSFieldNotFoundException       = @"kPGTSFieldNotFoundException";
NSString* const kPGTSNoPrimaryKeyException        = @"kPGTSNoPrimaryKeyException";
NSString* const kPGTSQueryFailedException         = @"kPGTSQueryFailedException";
NSString* const kPGTSConnectionFailedException    = @"kPGTSConnectionFailedException";

NSString* const kPGTSModificationNameKey          = @"kPGTSModificationNameKey";
NSString* const kPGTSInsertModification           = @"kPGTSInsertModification";
NSString* const kPGTSUpdateModification           = @"kPGTSUpdateModification";
NSString* const kPGTSDeleteModification           = @"kPGTSDeleteModification";

NSString* const kPGTSRowShareLock                 = @"kPGTSRowShareLock";
NSString* const kPGTSLockedForUpdate              = @"kPGTSLockedForUpdate";
NSString* const kPGTSLockedForDelete              = @"kPGTSLockedForDelete";
NSString* const kPGTSUnlockedRowsNotification     = @"kPGTSUnlockedRowsNotification";

NSString* const kPGTSUnsupportedPredicateOperatorTypeException = @"kPGTSUnsupportedPredicateOperatorTypeException";
NSString* const kPGTSParametersKey = @"kPGTSParametersKey";
NSString* const kPGTSParameterIndexKey = @"kPGTSParameterIndexKey";
NSString* const kPGTSExpressionParametersVerbatimKey = @"kPGTSExpressionParametersVerbatimKey";

NSString* const kPGTSErrorDomain                  = @"kPGTSErrorDomain";
NSString* const kPGTSConnectionErrorDomain        = @"kPGTSConnectionErrorDomain";

NSString* const kPGTSErrorSeverity                = @"kPGTSErrorSeverity";
NSString* const kPGTSErrorSQLState                = @"kPGTSErrorSQLState";
NSString* const kPGTSErrorPrimaryMessage          = @"kPGTSErrorPrimaryMessage";
NSString* const kPGTSErrorDetailMessage           = @"kPGTSErrorDetailMessage";
NSString* const kPGTSErrorHint                    = @"kPGTSErrorHint";
NSString* const kPGTSErrorInternalQuery           = @"kPGTSErrorInternalQuery";
NSString* const kPGTSErrorContext                 = @"kPGTSErrorContext";
NSString* const kPGTSErrorSourceFile              = @"kPGTSErrorSourceFile";
NSString* const kPGTSErrorSourceFunction          = @"kPGTSErrorSourceFunction";
NSString* const kPGTSErrorStatementPosition       = @"kPGTSErrorStatementPosition";
NSString* const kPGTSErrorInternalPosition        = @"kPGTSErrorInternalPosition";
NSString* const kPGTSErrorSourceLine              = @"kPGTSErrorSourceLine";
NSString* const kPGTSErrorMessage				  = @"kPGTSErrorMessage";
NSString* const kPGTSSSLAttemptedKey			  = @"kPGTSSSLAttemptedKey";


/* Declared in PGTSConnectionDelegate.h */
SEL kPGTSSentQuerySelector                  = NULL;
SEL kPGTSFailedToSendQuerySelector          = NULL;
SEL kPGTSAcceptCopyingDataSelector          = NULL;
SEL kPGTSReceivedDataSelector               = NULL;
SEL kPGTSReceivedResultSetSelector          = NULL;
SEL kPGTSReceivedErrorSelector              = NULL;
SEL kPGTSReceivedNoticeSelector             = NULL;

SEL kPGTSConnectionFailedSelector           = NULL;
SEL kPGTSConnectionEstablishedSelector      = NULL;
SEL kPGTSStartedReconnectingSelector        = NULL;
SEL kPGTSDidReconnectSelector               = NULL;
