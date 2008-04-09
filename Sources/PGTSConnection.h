//
// PGTSConnection.h
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

#import <Foundation/Foundation.h>
#import <PGTS/postgresql/libpq-fe.h>
@class PGTSResultSet;
@class PGTSConnector;
@class PGTSQueryDescription;

@interface PGTSConnection : NSObject
{
	PGConn* mConnection;
	NSMutableArray* mQueue;
	id mConnector;
}
- (id) init;
- (void) dealloc;
- (BOOL) connectAsync: (NSString *) connectionString;
- (void) disconnect;
@end


@interface PGTSConnection ()
- (void) setConnector: (PGTSConnector *) anObject;
- (void) readFromSocket;
- (int) sendNextQuery;
- (int) sendOrEnqueueQuery: (PGTSQueryDescription *) query;
@end


@interface PGTSConnection (PGTSConnectorDelegate)
- (void) connector: (PGTSConnector*) connector gotConnection: (PGConn *) connection succeeded: (BOOL) succeeded;
@end


@interface PGTSConnection (Queries)
- (PGTSResultSet *) executeQuery: (NSString *) queryString;
- (PGTSResultSet *) executeQuery: (NSString *) queryString parameters: (id) p1, ...;
- (PGTSResultSet *) executeQuery: (NSString *) queryString parameterArray: (NSArray *) parameters;
- (int) sendQuery: (NSString *) queryString delegate: (id) delegate callback: (SEL) callback;
- (int) sendQuery: (NSString *) queryString delegate: (id) delegate callback: (SEL) callback parameters: (id) p1, ...;
- (int) sendQuery: (NSString *) queryString delegate: (id) delegate callback: (SEL) callback parameterArray: (NSArray *) parameters;
@end