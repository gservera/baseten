//
// BXTestCase.m
// BaseTen
//
// Copyright 2009-2010 Marko Karppinen & Co. LLC.
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

#import <SenTestingKit/SenTestingKit.h>
#import <BaseTen/BaseTen.h>
#import <BaseTen/PGTSConstants.h>
#import "BXTestCase.h"
#import "MKCSenTestCaseAdditions.h"


int d_eq (double a, double b)
{
	double aa = fabs (a);
	double bb = fabs (b);
	return (fabs (aa - bb) <= (FLT_EPSILON * MAX (aa, bb)));
}



@interface SenTestCase (UndocumentedMethods)
- (void) logException:(NSException *) anException;
@end



@implementation BXTestCase
static void
bx_test_failed (NSException* exception)
{
	abort ();
}


- (void) logAndCallBXTestFailed: (NSException *) exception
{
	[self logException: exception];
	bx_test_failed (exception);
}


- (id) initWithInvocation: (NSInvocation *) anInvocation
{
	if ((self = [super initWithInvocation: anInvocation]))
	{
		[self setFailureAction: @selector (logAndCallBXTestFailed:)];
	}
	return self;
}


- (NSURL *) databaseURI
{
	return [NSURL URLWithString: @"pgsql://baseten_test_user@localhost/basetentest"];
}


- (NSDictionary *) connectionDictionary
{
	NSDictionary* connectionDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
										  @"localhost", kPGTSHostKey,
										  @"baseten_test_user", kPGTSUserNameKey,
										  @"basetentest", kPGTSDatabaseNameKey,
										  @"disable", kPGTSSSLModeKey,
										  nil];
	return connectionDictionary;
}

- (enum BXSSLMode) SSLModeForDatabaseContext: (BXDatabaseContext *) ctx
{
	return kBXSSLModeDisable;
}


- (void) setUp
{
	[super setUp];
	mPool = [[NSAutoreleasePool alloc] init];
}


- (void) tearDown
{
	[mPool drain];
	[super tearDown];
}
@end



@implementation BXDatabaseTestCase
- (void) setUp
{
	[super setUp];
	mStorage = [[BXDatabaseObjectModelStorage alloc] init];
	
	NSURL* databaseURI = [self databaseURI];
	mContext = [[BXDatabaseContext alloc] init];
	[mContext setDatabaseObjectModelStorage: mStorage];
	[mContext setDatabaseURI: databaseURI];
	[mContext setAutocommits: NO];
	[mContext setDelegate: self];
	
	MKCAssertFalse ([mContext autocommits]);
}


- (void) tearDown
{
	[mContext disconnect];
	[mContext release];
	[mStorage release];
	[super tearDown];
}
@end
