//
//  BXDatabaseTestCase.m
//  BaseTen
//
//  Created by Guillem on 13/9/14.
//
//

#import "BXDatabaseTestCase.h"
#import <BaseTen/PGTSConstants.h>

@implementation BXDatabaseTestCase

- (void)setUp {
    [super setUp];
    mStorage = [[BXDatabaseObjectModelStorage alloc] init];
    
    NSURL* databaseURI = [self databaseURI];
    mContext = [[BXDatabaseContext alloc] init];
    [mContext setDatabaseObjectModelStorage: mStorage];
    [mContext setDatabaseURI: databaseURI];
    [mContext setAutocommits: NO];
    [mContext setDelegate: self];
    
    XCTAssertFalse ([mContext autocommits]);
}


- (void)tearDown {
    [mContext disconnect];
    mContext = nil;
    mStorage = nil;
    [super tearDown];
}

#pragma mark - DB

- (NSURL *)databaseURI {
    return [NSURL URLWithString: @"pgsql://baseten_test_user@localhost/basetentest"];
}


- (NSDictionary *)connectionDictionary {
    return @{kPGTSHostKey : @"localhost",
             kPGTSUserNameKey : @"baseten_test_user",
             kPGTSDatabaseNameKey : @"basetentest",
             kPGTSSSLModeKey : @"disable"};
}

- (enum BXSSLMode)SSLModeForDatabaseContext: (BXDatabaseContext *)ctx {
    return kBXSSLModeDisable;
}

@end
