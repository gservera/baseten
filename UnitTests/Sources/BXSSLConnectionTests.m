//
// BXSSLConnectionTests.m
// BaseTen
//
// Copyright 2009 Marko Karppinen & Co. LLC.
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

#import "BXSSLConnectionTests.h"
#import "MKCSenTestCaseAdditions.h"


@implementation BXSSLConnectionTests
- (void) setUp
{
	[super setUp];
	
	mSSLMode = kBXSSLModeUndefined;
	mCertificatePolicy = kBXCertificatePolicyUndefined;
	
    mContext = [[BXDatabaseContext alloc] init];
	[mContext setAutocommits: NO];
	[mContext setDelegate: self];
	[mContext setDatabaseURI: [self databaseURI]];
}


- (void) tearDown
{
	XCTAssertFalse (kBXSSLModeUndefined == mSSLMode, @"SSL mode should've been set in the test.");
	XCTAssertFalse (kBXCertificatePolicyUndefined == mCertificatePolicy, @"Certificate policy should've been set in the test.");
	[mContext disconnect];
    [mContext release];
	[super tearDown];
}


- (enum BXSSLMode) SSLModeForDatabaseContext: (BXDatabaseContext *) ctx
{
	return mSSLMode;
}


- (enum BXCertificatePolicy) databaseContext: (BXDatabaseContext *) ctx 
						  handleInvalidTrust: (SecTrustRef) trust 
									  result: (SecTrustResultType) result
{
	return mCertificatePolicy;
}


- (void) testRequireSSLWithAllow
{
	mSSLMode = kBXSSLModeRequire;
	mCertificatePolicy = kBXCertificatePolicyAllow;
	
	NSError* error = nil;
	BOOL status = [mContext connectSync: &error];
	XCTAssertTrue (status, @"%@",[error description]);
	MKCAssertTrue ([mContext isSSLInUse]);
}


- (void) testPreferSSLWithAllow
{
	mSSLMode = kBXSSLModePrefer;
	mCertificatePolicy = kBXCertificatePolicyAllow;

	NSError* error = nil;
	BOOL status = [mContext connectSync: &error];
	XCTAssertTrue (status,@"%@", [error description]);
	MKCAssertTrue ([mContext isSSLInUse]);	
}


- (void) testRequireSSLWithDeny
{
	mSSLMode = kBXSSLModeRequire;
	mCertificatePolicy = kBXCertificatePolicyDeny;
	
	NSError* error = nil;
	BOOL status = [mContext connectSync: &error];
	MKCAssertFalse (status);
	MKCAssertNotNil (error);
	MKCAssertTrue ([kBXErrorDomain isEqualToString: [error domain]]);
	MKCAssertTrue (kBXErrorSSLCertificateVerificationFailed == [error code]);
}


- (void) testPreferSSLWithDeny
{
	mSSLMode = kBXSSLModePrefer;
	mCertificatePolicy = kBXCertificatePolicyDeny;
	
	NSError* error = nil;
	BOOL status = [mContext connectSync: &error];
	MKCAssertFalse (status);
	MKCAssertNotNil (error);
	MKCAssertTrue ([kBXErrorDomain isEqualToString: [error domain]]);
	MKCAssertTrue (kBXErrorSSLCertificateVerificationFailed == [error code]);	
}
@end
