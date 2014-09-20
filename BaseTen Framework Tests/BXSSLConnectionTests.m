//
//  BXSSLConnectionTests.m
//  BaseTen
//
//  Created by Guillem on 13/9/14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <BaseTen/BaseTen.h>

@interface BXSSLConnectionTests : XCTestCase <BXDatabaseContextDelegate>
{
    BXDatabaseContext* mContext;
    enum BXSSLMode mSSLMode;
    enum BXCertificatePolicy mCertificatePolicy;
}
@end

@implementation BXSSLConnectionTests

- (NSURL *)databaseURI {
    return [NSURL URLWithString: @"pgsql://baseten_test_user@localhost/basetentest"];
}

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
    mContext = nil;
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
    XCTAssertTrue ([mContext isSSLInUse]);
}


- (void) testPreferSSLWithAllow
{
    mSSLMode = kBXSSLModePrefer;
    mCertificatePolicy = kBXCertificatePolicyAllow;
    
    NSError* error = nil;
    BOOL status = [mContext connectSync: &error];
    XCTAssertTrue (status,@"%@", [error description]);
    XCTAssertTrue ([mContext isSSLInUse]);
}


- (void) testRequireSSLWithDeny
{
    mSSLMode = kBXSSLModeRequire;
    mCertificatePolicy = kBXCertificatePolicyDeny;
    
    NSError* error = nil;
    BOOL status = [mContext connectSync: &error];
    XCTAssertFalse (status);
    XCTAssertNotNil (error);
    XCTAssertTrue ([kBXErrorDomain isEqualToString: [error domain]]);
    XCTAssertTrue (kBXErrorSSLCertificateVerificationFailed == [error code]);
}


- (void) testPreferSSLWithDeny
{
    mSSLMode = kBXSSLModePrefer;
    mCertificatePolicy = kBXCertificatePolicyDeny;
    
    NSError* error = nil;
    BOOL status = [mContext connectSync: &error];
    XCTAssertFalse (status);
    XCTAssertNotNil (error);
    XCTAssertTrue ([kBXErrorDomain isEqualToString: [error domain]]);
    XCTAssertTrue (kBXErrorSSLCertificateVerificationFailed == [error code]);
}


@end
