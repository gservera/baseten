//
// PGTSConnector.h
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

@class PGTSConnector;


@protocol PGTSConnectorDelegate <NSObject>
- (void) connector: (PGTSConnector*) connector gotConnection: (PGconn *) connection succeeded: (BOOL) succeeded;
@end


@interface PGTSConnector : NSObject
{
	id <PGTSConnectorDelegate> mDelegate;
	PostgresPollingStatusType (* mPollFunction)(PGconn *);
	PGconn* mConnection;
}
- (BOOL) connect: (const char *) connectionString;
- (void) cancel;
- (void) setDelegate: (id <PGTSConnectorDelegate>) anObject;
- (void) setConnection: (PGconn *) connection;

- (BOOL) start: (const char *) connectionString;
@end


@interface PGTSAsynchronousConnector : PGTSConnector
{
	CFRunLoopRef mRunLoop;
	CFSocketRef mSocket;
	CFRunLoopSourceRef mSocketSource;
	BOOL mSSLSetUp;
}
- (void) socketReady;
- (void) finishedConnecting: (BOOL) succeeded;
@end


@interface PGTSSynchronousConnector : PGTSConnector
{
}
@end


@interface PGTSAsynchronousReconnector : PGTSAsynchronousConnector
{
}
@end


@interface PGTSSynchronousReconnector : PGTSSynchronousConnector
{
}
@end