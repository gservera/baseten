//
// BXDatabaseContextDelegateProtocol.h
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
#import <Security/Security.h>
#import <BaseTen/BXConstants.h>
#import <SystemConfiguration/SystemConfiguration.h>


@class BXDatabaseContext;
@class BXEntityDescription;


/**
 * The protocol the database context's delegate needs to implement.
 * \note Most of the protocol is declared optional.
 */
@protocol BXDatabaseContextDelegate <NSObject>

//Optional section of the protocol either as an interface or @optional.
/** \cond */
#if __MAC_OS_X_VERSION_10_5 <= __MAC_OS_X_VERSION_MAX_ALLOWED
/** \endcond */ 
@optional
/** \cond */
#else
@end
@interface NSObject (BXDatabaseContextDelegate)
#endif
/** \endcond */ 

/**
 * Callback for a successful connection.
 * Called after a successful asynchronous connection attempt.
 * \param ctx The database context that initiated the connection.
 */
- (void) databaseContextConnectionSucceeded: (BXDatabaseContext *) ctx;

/**
 * Callback for a failed connection.
 * Called after a failed asynchronous connection attempt.
 * \param ctx The database context that initiated the connection.
 * \param error The connection error.
 */
- (void) databaseContext: (BXDatabaseContext *) ctx failedToConnect: (NSError *) error;

/**
 * Callback for a failed connection.
 * When BaseTenAppKit is linked, BXDatabaseContext automatically displays an alert panel.
 * This method will be called after the user has dismissed the panel.
 * \param ctx The database context that initiated the connection.
 */
- (void) databaseContextConnectionFailureAlertDismissed: (BXDatabaseContext *) ctx;

/**
 * Handle an error.
 * Various methods in BXDatabaseContext have an NSError** parameter. In addition,
 * the context has an errorHandlerDelegate outlet. If no error handler has been 
 * set, the database context will handle errors itself. 
 * 
 * When the NSError** parameter has been supplied to the methods, no action 
 * will be taken and the error is assumed to have been handled. If the parameter
 * is NULL and an error occurs, a BXException named \em kBXExceptionUnhandledError
 * will be thrown.
 *
 * \param context			The database context from which the error originated.
 * \param anError			The error.
 * \param willBePassedOn	Whether the calling method's NSError** parameter was set or not.
 */
- (void) databaseContext: (BXDatabaseContext *) context 
				hadError: (NSError *) anError 
		  willBePassedOn: (BOOL) willBePassedOn;

/**
 * Handle connection loss.
 * Called when a database connection is lost either unintentionally or by system sleep.
 * In both cases a recovery attempter will be included with the error.
 *
 * By default in AppKit applications the error will be presented to the user as an 
 * application modal alert panel. If they choose not to reconnect or the attempt fails 
 * for some reason, the context will be set to return \em nil for all non-cached object 
 * values.
 *
 * Foundation applications will throw a BXException named \em kBXExceptionUnhandledError.
 * 
 * \note -databaseContext:hadError:willBePassedOn: won't be called for this error.
 */
- (void) databaseContext: (BXDatabaseContext *) context lostConnection: (NSError *) error;

/**
 * Handle failure during connection loss recovery.
 * Called after recovery was attempted after a database connection had been lost but
 * the attempt failed.
 *
 * By default in AppKit applications the error will be presented to the user as an
 * application modal alert panel.
 *
 * Foundation applications will log the error.
 *
 * \note -databaseContext:hadError:willBePassedOn: won't be called for this error.
 */
- (void) databaseContext: (BXDatabaseContext *) context
	hadReconnectionError: (NSError *) error;

/**
 * Policy for invalid trust.
 * The server certificate will be verified using the system keychain. On failure this 
 * method will be called. The delegate may then accept or deny the certificate or, in
 * case the application has been linked to the BaseTenAppKit framework, ask the context
 * to display a trust panel to the user.
 * \param ctx     The database context making the connection
 * \param trust   A trust created from the certificate
 * \param result  Initial verification result
 */
- (enum BXCertificatePolicy) databaseContext: (BXDatabaseContext *) ctx 
						  handleInvalidTrust: (SecTrustRef) trust 
									  result: (SecTrustResultType) result;

/**
 * Secure connection mode for the context.
 * The mode may be one of require, disable and prefer. In prefer mode,
 * a secure connection will be attempted. If this fails for other reason
 * than a certificate verification problem, an insecure connection
 * will be tried.
 */
- (enum BXSSLMode) SSLModeForDatabaseContext: (BXDatabaseContext *) ctx;

- (void) databaseContextGotDatabaseURI: (BXDatabaseContext *) ctx;

/**
 * Network status change.
 * Changes in network status are received from System Configuration framework.
 * \note The default implementation does nothing but this might change in the future.
 */
- (void) databaseContext: (BXDatabaseContext *) context
	networkStatusChanged: (SCNetworkConnectionFlags) newFlags;
@end
