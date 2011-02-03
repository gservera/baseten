//
// BXDelegateProxy.m
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

#import "BXDelegateProxy.h"



/** 
 * \internal
 * \brief A delegate proxy for cases where a default implementation is needed.
 *
 * \note This class should be thread safe after it has been instantiated
 *       as it only uses NSProxy's methods that are expected to be thread safe.
 * \ingroup basetenutility
 */
@implementation BXDelegateProxy
/**
 * \brief Create the proxy.
 * \param anObject The object that contains the default implementations.
 * \note  This method is not thread safe.
 */
- (id) initWithDelegateDefaultImplementation: (id) anObject
{
	mDelegateDefaultImplementation = [anObject retain];
	return self;
}


- (void) dealloc
{
	[mDelegateDefaultImplementation release];
	[super dealloc];
}


/**
 * \brief Set the partial delegate.
 * \param anObject The object that contains the primary implementations.
 * \note  This method is not thread safe.
 */
- (void) setDelegateForBXDelegateProxy: (id) anObject
{
	mDelegate = anObject;
}


- (NSMethodSignature *) methodSignatureForSelector: (SEL) aSelector
{
	NSMethodSignature* retval = [mDelegate methodSignatureForSelector: aSelector];
	if (! retval)
		retval = [mDelegateDefaultImplementation methodSignatureForSelector: aSelector];
	return retval;
}


- (void) forwardInvocation: (NSInvocation *) invocation
{
	SEL selector = [invocation selector];
	if ([mDelegate respondsToSelector: selector])
		[invocation invokeWithTarget: mDelegate];
	else if ([mDelegateDefaultImplementation respondsToSelector: selector])
		[invocation invokeWithTarget: mDelegateDefaultImplementation];
}
@end
