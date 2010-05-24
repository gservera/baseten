//
// BXDelegateProxy.m
// BaseTen
//
// Copyright (C) 2006-2008 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://basetenframework.org/licensing/ or by contacting
// us at sales@karppinen.fi. Without an additional license, this software
// may be distributed only in compliance with the GNU General Public License.
//
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License, version 2.0,
// as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
// $Id$
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
