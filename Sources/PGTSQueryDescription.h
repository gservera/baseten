//
// PGTSQueryDescription.h
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
@class PGTSQuery;
@class PGTSConnection;
@class PGTSResultSet;


@interface PGTSQueryDescription : NSObject
{
}
+ (PGTSQueryDescription *) queryDescriptionFor: (NSString *) queryString 
									  delegate: (id) delegate 
									  callback: (SEL) callback 
								parameterArray: (NSArray *) parameters 
									  userInfo: (id) userInfo;

- (SEL) callback;
- (void) setCallback: (SEL) aSel;
- (id) delegate;
- (void) setDelegate: (id) anObject;
- (NSInteger) identifier;
- (PGTSQuery *) query;
- (void) setQuery: (PGTSQuery *) aQuery;
- (void) setUserInfo: (id) userInfo;
- (BOOL) sent;
- (BOOL) finished;

- (int) sendForConnection: (PGTSConnection *) connection;
- (PGTSResultSet *) receiveForConnection: (PGTSConnection *) connection;
- (PGTSResultSet *) finishForConnection: (PGTSConnection *) connection;

@end


@interface PGTSConcreteQueryDescription : PGTSQueryDescription
{
	SEL mCallback;
	id mDelegate; //Weak
	NSInteger mIdentifier;
	PGTSQuery* mQuery;
	id mUserInfo;
	BOOL mSent;
	BOOL mFinished;
}
@end