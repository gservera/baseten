//
// BXHostResolver.m
// BaseTen
//
// Copyright 2010 Marko Karppinen & Co. LLC.
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


#import "BXHostResolver.h"
#import "BXLogger.h"
#import "BXError.h"
#import "BXConstants.h"
#import "BXCFHostCompatibility.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <netdb.h>



@interface BXHostResolver ()
- (void) _setNodeName: (NSString *) nodeName;
- (void) _setAddresses: (NSArray *) addresses;

- (NSError *) _errorForStreamError: (const CFStreamError *) streamError;

- (void) _reachabilityCheckDidComplete: (SCNetworkConnectionFlags) flags;
- (void) _hostCheckDidComplete: (const CFStreamError *) streamError;

- (void) _removeReachability;
- (void) _removeHost;
@end



static NSArray * 
CopySockaddrArrayFromAddrinfo (struct addrinfo *addrinfo)
{
	NSMutableArray *retval = [NSMutableArray array];
	while (addrinfo)
	{
		NSData *address = [NSData dataWithBytes: addrinfo->ai_addr length: addrinfo->ai_addrlen];
		[retval addObject: address];
		addrinfo = addrinfo->ai_next;
	}
	return [retval copy];
}


static void
ReachabilityCallback (SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *info)
{
	[(id) info _reachabilityCheckDidComplete: flags];
}


static void 
HostCallback (CFHostRef theHost, CFHostInfoType typeInfo, const CFStreamError *error, void *info)
{
	[(id) info _hostCheckDidComplete: error];
}



/**
 * \internal
 * \brief A façade for CFHost that also tests reachability.
 * \note Instances of this class can safely be used from only one thread at a time.
 */
@implementation BXHostResolver
/**
 * \brief Test whether a given address is numeric.
 * \note This method is thread safe.
 */
+ (BOOL) getAddrinfo: (struct addrinfo **) outAddrinfo forIPAddress: (NSString *) node
{
	ExpectR (outAddrinfo, NO);
	ExpectR (0 < [node length], NO);
	
	struct addrinfo hints = {
		AI_NUMERICHOST,
		PF_UNSPEC,
		0,
		0,
		0,
		NULL,
		NULL
	};
	int status = getaddrinfo ([node UTF8String], NULL, &hints, outAddrinfo);
	[node self]; //For GC
	return (0 == status ? YES : NO);
}


- (void) dealloc
{	
	[self _removeReachability];
	[self _removeHost];
	
	if (mRunLoop)
		CFRelease (mRunLoop);
	
	[mRunLoopMode release];
	[super dealloc];
}


- (void) finalize
{
	[self _removeReachability];
	[self _removeHost];

	if (mRunLoop)
		CFRelease (mRunLoop);
	
	[super finalize];
}


- (void) cancelResolution
{
	[self _removeReachability];
	[self _removeHost];
}


- (void) _removeReachability
{
	if (mReachability)
	{
		SCNetworkReachabilityUnscheduleFromRunLoop (mReachability, mRunLoop, (CFStringRef) mRunLoopMode);
		SCNetworkReachabilitySetCallback (mReachability, NULL, NULL);
		CFRelease (mReachability);
		mReachability = NULL;
	}
}


- (void) _removeHost
{
	if (mHost)
	{
		CFHostCancelInfoResolution (mHost, kCFHostAddresses);
		CFHostUnscheduleFromRunLoop (mHost, mRunLoop, (CFStringRef) mRunLoopMode);
		CFHostSetClient (mHost, NULL, NULL);
		CFRelease (mHost);
		mHost = NULL;
	}
}


/**
 * \brief Resolve the given host.
 */
- (void) resolveHost: (NSString *) host
{	
	ExpectV (mRunLoop);
	ExpectV (mRunLoopMode);
	ExpectV (host);
	ExpectV ([host characterAtIndex: 0] != '/');	
	
	[self _removeReachability];
	[self _removeHost];
	bzero (&mHostError, sizeof (mHostError));

	[self _setNodeName: host];
	SCNetworkReachabilityContext ctx = {
		0,
		self,
		NULL,
		NULL,
		NULL
	};
	Boolean status = FALSE;
	
	struct addrinfo *addrinfo = NULL;
	if ([[self class] getAddrinfo: &addrinfo forIPAddress: host])
	{
		NSArray *addresses = CopySockaddrArrayFromAddrinfo (addrinfo);
		[self _setAddresses: addresses];
		[addresses release];
		
		mReachability = SCNetworkReachabilityCreateWithAddress (kCFAllocatorDefault, addrinfo->ai_addr);
		
		// For some reason the reachability check doesn't work with numeric addresses when using the run loop.
		SCNetworkConnectionFlags flags = 0;
		status = SCNetworkReachabilityGetFlags (mReachability, &flags);
		ExpectL (status)
		
		[self _reachabilityCheckDidComplete: flags];
	}
	else
	{
		mReachability = SCNetworkReachabilityCreateWithName (kCFAllocatorDefault, [host UTF8String]);

		status = SCNetworkReachabilitySetCallback (mReachability, &ReachabilityCallback, &ctx);
		ExpectL (status);
		
		status = SCNetworkReachabilityScheduleWithRunLoop (mReachability, mRunLoop, (CFStringRef) mRunLoopMode);
		ExpectL (status);		
	}
	
	if (addrinfo)
		freeaddrinfo (addrinfo);

	[host self]; // For GC.
}


- (void) _reachabilityCheckDidComplete: (SCNetworkConnectionFlags) actual
{
	// We use the old type name, since the new one only appeared in 10.6.
	
	[self _removeReachability];
	bzero (&mHostError, sizeof (mHostError));
	
	if (mAddresses)
	{
		//Any flag in "required" will suffice. (Hence not 'required == (required & actual)'.)
		SCNetworkConnectionFlags required = kSCNetworkFlagsReachable | kSCNetworkFlagsConnectionAutomatic;	
		if ((required & actual) && [mAddresses count])
			[mDelegate hostResolverDidSucceed: self addresses: mAddresses];
		else
		{
			// The given address was numeric but isn't reachable. Since SCNetworkReachability
			// doesn't provide us with good error messages, we settle with a generic one.
			mHostError.domain = kCFStreamErrorDomainSystemConfiguration;
			[mDelegate hostResolverDidFail: self error: [self _errorForStreamError: &mHostError]];
		}
	}
	else
	{
		Boolean status = FALSE;			
		mHost = CFHostCreateWithName (CFAllocatorGetDefault (), (CFStringRef) mNodeName);
		CFHostClientContext ctx = {
			0,
			self,
			NULL,
			NULL,
			NULL
		};
		status = CFHostSetClient (mHost, &HostCallback, &ctx);
		CFHostScheduleWithRunLoop (mHost, mRunLoop, (CFStringRef) mRunLoopMode);
		
		if (! CFHostStartInfoResolution (mHost, kCFHostAddresses, &mHostError))
			[self _hostCheckDidComplete: &mHostError];
	}
}


- (void) _hostCheckDidComplete: (const CFStreamError *) streamError
{	
	if (streamError && streamError->domain)
	{
		NSError *error = [self _errorForStreamError: streamError];
		[mDelegate hostResolverDidFail: self error: error];
	}
	else
	{
		Boolean status = FALSE;
		[mDelegate hostResolverDidSucceed: self addresses: (id) CFHostGetAddressing (mHost, &status)];
	}
	
	[self _removeHost];
}


- (NSError *) _errorForStreamError: (const CFStreamError *) streamError
{
	NSError* retval = nil;
	if (streamError)
	{
		// Create an error. The domain field in CFStreamError is a CFIndex, so we need to replace it with something
		// more suitable for NSErrors. According to the documentation, kCFStreamErrorDomainNetDB and
		// kCFStreamErrorDomainSystemConfiguration are avaible in Mac OS X 10.5, so we need to check
		// symbol existence, too.
		NSString* errorTitle = NSLocalizedStringWithDefaultValue (@"connectionError", nil, [NSBundle bundleForClass: [self class]],
																  @"Connection error", @"Title for a sheet.");

		const char* reason = NULL;
		NSString* messageFormat = nil; //FIXME: localization.
		if (streamError->domain == kCFStreamErrorDomainNetDB)
		{
			reason = (gai_strerror (streamError->error)); //FIXME: check that this returns locale-specific strings.
			if (reason)
				messageFormat = @"The server %@ wasn't found: %s.";
			else
				messageFormat = @"The server %@ wasn't found.";
		}
		else if (streamError->domain == kCFStreamErrorDomainSystemConfiguration)
		{
			messageFormat = @"The server %@ wasn't found. Network might be unreachable.";
		}
		else
		{
			// In case the domain field hasn't been set, return a generic error.
			messageFormat = @"The server %@ wasn't found.";
		}
		NSString* message = [NSString stringWithFormat: messageFormat, mNodeName, reason];

		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  errorTitle, NSLocalizedDescriptionKey,
								  errorTitle, NSLocalizedFailureReasonErrorKey,
								  message, NSLocalizedRecoverySuggestionErrorKey,
								  [NSValue valueWithBytes: streamError objCType: @encode (CFStreamError)], kBXStreamErrorKey,
								  nil];
		retval = [BXError errorWithDomain: kBXErrorDomain code: kBXErrorHostResolutionFailed userInfo: userInfo];
	}
	return retval;
}


- (void) _setNodeName: (NSString *) nodeName
{
	if (nodeName != mNodeName)
	{
		[mNodeName release];
		mNodeName = [nodeName retain];
	}
}


- (void) _setAddresses: (NSArray *) addresses
{
	if (addresses != mAddresses)
	{
		[mAddresses release];
		mAddresses = [addresses retain];
	}
}
@end



@implementation BXHostResolver (Accessors)
- (NSString *) runLoopMode;
{
	return mRunLoopMode;
}


- (void) setRunLoopMode: (NSString *) mode
{
	if (mode != mRunLoopMode)
	{
		[self _removeHost];
		
		[mRunLoopMode release];
		mRunLoopMode = [mode retain];
	}
}


- (CFRunLoopRef) runLoop
{
	return mRunLoop;
}


- (void) setRunLoop: (CFRunLoopRef) runLoop
{
	if (runLoop != mRunLoop)
	{
		[self _removeHost];
		
		if (mRunLoop)
			CFRelease (mRunLoop);
		
		mRunLoop = runLoop;
		
		if (mRunLoop)
			CFRetain (mRunLoop);
	}
}


- (id <BXHostResolverDelegate>) delegate
{
	return mDelegate;
}


- (void) setDelegate: (id <BXHostResolverDelegate>) delegate
{
	mDelegate = delegate;
}
@end
