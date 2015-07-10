//
// BXLogger.h
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
#import <stdarg.h>
#import <mach-o/dyld.h>
#import <BaseTen/BXExport.h>

/**
 * \file
 * Logging and assertion functions used by BaseTen.
 */


#define BX_LOG_ARGS __BASE_FILE__, __PRETTY_FUNCTION__, __builtin_return_address(0), __LINE__


//Note that " , ##__VA_ARGS__" tells the preprocessor to remove the comma if __VA_ARGS__ is empty.
#define BXLogDebug(message, ...)   do { if (BXLogLevel >= kBXLogLevelDebug)   BXLog (BX_LOG_ARGS, kBXLogLevelDebug,   message , ##__VA_ARGS__); } while (0)
#define BXLogInfo(message, ...)    do { if (BXLogLevel >= kBXLogLevelInfo)    BXLog (BX_LOG_ARGS, kBXLogLevelInfo,    message , ##__VA_ARGS__); } while (0)
#define BXLogWarning(message, ...) do { if (BXLogLevel >= kBXLogLevelWarning) BXLog (BX_LOG_ARGS, kBXLogLevelWarning, message , ##__VA_ARGS__); } while (0)
#define BXLogError(message, ...)   do { if (BXLogLevel >= kBXLogLevelError)   BXLog (BX_LOG_ARGS, kBXLogLevelError,   message , ##__VA_ARGS__); } while (0)
#define BXLogFatal(message, ...)   do { if (BXLogLevel >= kBXLogLevelFatal)   BXLog (BX_LOG_ARGS, kBXLogLevelFatal,   message , ##__VA_ARGS__); } while (0)

#define BXAssertLog(assertion, message, ...) \
	do { if (! (assertion)) { BXLogError (message , ##__VA_ARGS__); BXAssertionDebug (); }} while (0)
#define BXAssertVoidReturn(assertion, message, ...) \
	do { if (! (assertion)) { BXLogError (message , ##__VA_ARGS__); BXAssertionDebug (); return; }} while (0)
#define BXAssertValueReturn(assertion, retval, message, ...) \
	do { if (! (assertion)) { BXLogError (message , ##__VA_ARGS__); BXAssertionDebug (); return (retval); }} while (0)
#define BXLogAssertionFailure(message, ...) \
	do { BXLogError (message , ##__VA_ARGS__); BXAssertionDebug (); } while (0)

#define BXDeprecationLogSpecific(...) \
	do { BXLogWarning (__VA_ARGS__); BXDeprecationWarning (); } while (0)
#define BXDeprecationLog() BXDeprecationLogSpecific(@"This method or function has been deprecated.");


//C function variants.
#define BXCAssertLog(...) BXAssertLog(__VA_ARGS__)
#define BXCAssertValueReturn(...) BXAssertValueReturn(__VA_ARGS__)
#define BXCAssertVoidReturn(...) BXAssertVoidReturn(__VA_ARGS__)
#define BXCLogAssertionFailure(...) BXLogAssertionFailure(__VA_ARGS__)
#define BXCDeprecationLogSpecific(...) BXDeprecationLogSpecific(__VA_ARGS__)
#define BXCDeprecationLog() BXDeprecationLog()


#define Expect( X )	BXAssertValueReturn( X, nil, @"Expected " #X " to evaluate to true.");
#define ExpectL( X ) BXAssertLog( X, @"Expected " #X " to evaluate to true.");
#define ExpectR( X, RETVAL )	BXAssertValueReturn( X, RETVAL, @"Expected " #X " to evaluate to true.");
#define ExpectV( X ) BXAssertVoidReturn( X, @"Expected " #X " to evaluate to true.");
//C function variants.
#define ExpectC( X ) Expect( X )
#define ExpectCL( X ) ExpectL( X )
#define ExpectCV( X ) ExpectV( X )
#define ExpectCR( X, RETVAL ) ExpectR( X, RETVAL )


/**
 * \brief
 * Logging levels used by BaseTen.
 */
enum BXLogLevel
{
	kBXLogLevelOff = 0, /**< No logging */
	kBXLogLevelFatal,   /**< Fatal errors */
	kBXLogLevelError,   /**< Errors */
	kBXLogLevelWarning, /**< Warnings */
	kBXLogLevelInfo,    /**< Information */
	kBXLogLevelDebug    /**< Debugging information */
};

// Do not use outside this file in case we decide to change the implementation.
// The symbol is also needed by BaseTenAppKit.
BX_EXPORT enum BXLogLevel BXLogLevel;


/**
 * \brief
 * Set the logging level
 *
 * \warning This function is not thread-safe.
 */
BX_EXPORT void BXLogSetLevel (enum BXLogLevel level);
BX_EXPORT void BXSetLogLevel (enum BXLogLevel level) BX_DEPRECATED_IN_1_8;

/**
 * \brief
 * Set whether the logger should call abort() on assertion failure
 *
 * \warning This function is not thread-safe.
 */
BX_EXPORT void BXLogSetAbortsOnAssertionFailure (BOOL);


/**
 * \brief A debugging helper.
 *
 * This function provides a convenient breakpoint. It will be called when
 * an assertion fails. The reason might be a bug in either BaseTen or in
 * user code.
 */
BX_EXPORT void BXAssertionDebug () BX_ANALYZER_NORETURN;


/**
 * \brief A debugging helper.
 *
 * This function provides a convenient breakpoint. It will be called when
 * deprecated functionality is invoked, presently when relationships with
 * deprecated names are used.
 */
BX_EXPORT void BXDeprecationWarning ();


#if ! (defined (TARGET_OS_IPHONE) && TARGET_OS_IPHONE)
BX_EXPORT void BXLogSetLogFile (NSBundle *bundle);
#endif


BX_EXPORT void BXLog (char const *fileName, 
					  char const *functionName, 
					  void const *functionAddress, 
					  int line, 
					  enum BXLogLevel level, 
					  NSString * const messageFmt, 
					  ...) BX_FORMAT_FUNCTION(6,7);
BX_EXPORT void BXLog_v (char const *fileName, 
						char const *functionName, 
						void const *functionAddress, 
						int line, 
						enum BXLogLevel level, 
						NSString * const messageFmt, 
						va_list args) BX_FORMAT_FUNCTION(6,0);
