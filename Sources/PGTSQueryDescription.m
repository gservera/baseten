//
// PGTSQueryDescription.m
// BaseTen
//
// Copyright (C) 2008 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://www.karppinen.fi/baseten/licensing/ or by contacting
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

#import "PGTSQueryDescription.h"
#import "PGTSConnection.h"
#import "PGTSResultSet.h"
#import "PGTSQuery.h"
#import "PGTSConnectionPrivate.h"
#import "PGTSProbes.h"
#import <BaseTen/libpq-fe.h>
#import <libkern/OSAtomic.h>



static int32_t
NextIdentifier ()
{
    // No barrier needed since we are only incrementing a counter.
	static volatile int32_t identifier = 0;
	return OSAtomicIncrement32 (&identifier);
}



@implementation PGTSQueryDescription
+ (PGTSQueryDescription *) queryDescriptionFor: (NSString *) queryString 
									  delegate: (id) delegate 
									  callback: (SEL) callback 
								parameterArray: (NSArray *) parameters 
									  userInfo: (id) userInfo
{
	PGTSQueryDescription* desc = [[[PGTSConcreteQueryDescription alloc] init] autorelease];
	PGTSParameterQuery* query = [[[PGTSParameterQuery alloc] init] autorelease];
	[query setQuery: queryString];
	[query setParameters: parameters];
	[desc setQuery: query];
	[desc setDelegate: delegate];
	[desc setCallback: callback];
	[desc setUserInfo: userInfo];
	return desc;	
}


- (NSString *) description
{
	NSString* retval = [NSString stringWithFormat: @"<%@ (%p): %@>",
						[self class],
						self,
						[[self query] query]];
	return retval;
}

- (SEL) callback
{
	return NULL;
}

- (void) setCallback: (SEL) aSel
{
}

- (id) delegate
{
	return nil;
}

- (void) setDelegate: (id) anObject
{
}

- (NSInteger) identifier
{
	return 0;
}

- (PGTSQuery *) query
{
	return nil;
}

- (void) setQuery: (PGTSQuery *) aQuery
{
}

- (BOOL) sent
{
	return NO;
}

- (BOOL) finished
{
	return YES;
}

- (int) sendForConnection: (PGTSConnection *) connection
{
    return -1;
}

- (PGTSResultSet *) receiveForConnection: (PGTSConnection *) connection
{
    return nil;
}

- (PGTSResultSet *) finishForConnection: (PGTSConnection *) connection
{
    return nil;
}

- (void) setUserInfo: (id) userInfo
{
}
@end


@implementation PGTSConcreteQueryDescription
- (void) dealloc
{
	[mQuery release];
	[mUserInfo release];
	[super dealloc];
}


- (id) init
{
	if ((self = [super init]))
	{
		mIdentifier = NextIdentifier ();
	}
	return self;
}


- (SEL) callback
{
	SEL retval = NULL;
	@synchronized (self)
	{
		retval = mCallback;
	}
	return retval;
}


- (void) setCallback: (SEL) aSel
{
	@synchronized (self)
	{
		mCallback = aSel;
	}
}

- (id) delegate
{
	id retval = nil;
	@synchronized (self)
	{
		retval = [[mDelegate retain] autorelease];
	}
	return retval;
}


- (void) setDelegate: (id) anObject
{
	@synchronized (self)
	{
		mDelegate = anObject;
	}
}


- (NSInteger) identifier
{
	// Not changed after -init.
	return mIdentifier;
}


- (PGTSQuery *) query
{
	PGTSQuery *retval = nil;
	@synchronized (self)
	{
		retval = [[mQuery retain] autorelease];
	}
	return retval;
}


- (void) setQuery: (PGTSQuery *) aQuery
{
	@synchronized (self)
	{
		if (mQuery != aQuery)
		{
			[mQuery release];
			mQuery = [aQuery retain];
		}
	}
}


- (BOOL) sent
{
	BOOL retval = NO;
	@synchronized (self)
	{
		retval = mSent;
	}
	return retval;
}


- (BOOL) finished
{
	BOOL retval = NO;
	@synchronized (self)
	{
		retval = mFinished;
	}
	return retval;
}


- (int) sendForConnection: (PGTSConnection *) connection
{
    int retval = [mQuery sendQuery: connection];
	if (0 < retval)
	{
		@synchronized (self)
		{
			mSent = YES;
		}
	}
	return retval;
}

- (PGTSResultSet *) receiveForConnection: (PGTSConnection *) connection
{	
    PGTSResultSet* retval = nil;
    PGconn* pgConn = [connection pgConnection];
    PGresult* result = PQgetResult (pgConn);
	
	@synchronized (self)
	{
		if (result)
		{
			retval = [PGTSResultSet resultWithPGresult: result connection: connection];
			[retval setIdentifier: mIdentifier];
			[retval setUserInfo: mUserInfo];
			
			[connection logIfNeeded: retval];
			[mDelegate performSelector: mCallback withObject: retval];
		}
		else
		{
			mFinished = YES;
			
			if (BASETEN_POSTGRESQL_FINISH_QUERY_ENABLED ())
				BASETEN_POSTGRESQL_FINISH_QUERY ();
		}
	}
    return retval;
}


- (PGTSResultSet *) finishForConnection: (PGTSConnection *) connection
{
    id retval = nil;
	@synchronized (self)
	{
		if (mSent || 0 < [self sendForConnection: connection])
		{
			while (! mFinished)
			{
				retval = [self receiveForConnection: connection] ?: retval;
				[connection _processNotifications];
			}
		}
	}
    return retval;
}


- (void) setUserInfo: (id) userInfo
{
	@synchronized (self)
	{
		if (mUserInfo != userInfo)
		{
			[mUserInfo release];
			mUserInfo = [userInfo retain];
		}
	}
}
@end
