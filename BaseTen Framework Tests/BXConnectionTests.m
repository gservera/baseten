//
//  BXConnectionTests.m
//  BaseTen
//
//  Created by Guillem on 13/9/14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <BaseTen/BaseTen.h>

@interface BXConnectionTests : XCTestCase <BXDatabaseContextDelegate> {
    BXDatabaseContext *mContext;
    NSInteger mExpectedCount;
}

@end

@implementation BXConnectionTests

- (void)setUp {
    [super setUp];
    
    mContext = [[BXDatabaseContext alloc] init];
    [mContext setAutocommits: NO];
    [mContext setDelegate: self];
}

- (void)tearDown {
    [mContext disconnect];
    mContext = nil;
    [super tearDown];
}

- (enum BXSSLMode) SSLModeForDatabaseContext: (BXDatabaseContext *) ctx
{
    return kBXSSLModeDisable;
}

- (NSURL *)databaseURI {
    return [NSURL URLWithString: @"pgsql://baseten_test_user@localhost/basetentest"];
}

- (void) waitForConnectionAttempts: (NSInteger) count
{
    for (NSInteger i = 0; i < 300; i++)
    {
        NSLog (@"Attempt %ld, count %ld, expected %ld", (long)i, (long)mExpectedCount, count);
        if (count == mExpectedCount)
            break;
        
        [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 2.0]];
    }
}

- (void)test1Connect {
    XCTAssertNoThrow ([mContext setDatabaseURI: [self databaseURI]]);
    XCTAssertNoThrow ([mContext connectIfNeeded: nil]);
}


- (void) test2Connect
{
    NSURL* uri = [self databaseURI];
    NSString* uriString = [uri absoluteString];
    uriString = [uriString stringByAppendingString: @"/"];
    uri = [NSURL URLWithString: uriString];
    
    XCTAssertNoThrow ([mContext setDatabaseURI: uri]);
    XCTAssertNoThrow ([mContext connectIfNeeded: nil]);
}


- (void) test3ConnectFail
{
    XCTAssertNoThrow ([mContext setDatabaseURI: [NSURL URLWithString: @"pgsql://localhost/anonexistantdatabase"]]);
    XCTAssertThrows ([mContext connectIfNeeded: nil]);
}


- (void) test4ConnectFail
{
    XCTAssertNoThrow ([mContext setDatabaseURI:
                       [NSURL URLWithString: @"pgsql://user@localhost/basetentest/a/malformed/database/uri"]]);
    XCTAssertThrows ([mContext connectIfNeeded: nil]);
}


- (void) test5ConnectFail
{
    XCTAssertThrows ([mContext setDatabaseURI: [NSURL URLWithString: @"invalid://user@localhost/invalid"]]);
}


- (void) test7NilURI
{
    NSError* error = nil;
    id fetched = nil;
    BXEntityDescription* entity = [[mContext databaseObjectModel] entityForTable: @"test"];
    fetched = [mContext executeFetchForEntity: entity withPredicate: nil error: &error];
    XCTAssertNotNil (error);
    fetched = [mContext createObjectForEntity: entity withFieldValues: nil error: &error];
    XCTAssertNotNil (error);
}


- (void) expected: (NSNotification *) n
{
    mExpectedCount++;
}


- (void) unexpected: (NSNotification *) n
{
    XCTAssertTrue (NO, @"Expected connection not to have been made.");
}


- (void) test6ConnectFail
{
    [mContext setDatabaseURI: [NSURL URLWithString: @"pgsql://localhost/anonexistantdatabase"]];
    [[mContext notificationCenter] addObserver: self selector: @selector (expected:) name: kBXConnectionFailedNotification object: nil];
    [[mContext notificationCenter] addObserver: self selector: @selector (unexpected:) name: kBXConnectionSuccessfulNotification object: nil];
    [mContext connectAsync];
    [self waitForConnectionAttempts: 1];
    [mContext connectAsync];
    [self waitForConnectionAttempts: 2];
    [mContext connectAsync];
    [self waitForConnectionAttempts: 3];
    XCTAssertTrue (3 == mExpectedCount, @"Expected 3 connection attempts while there were %ld.", mExpectedCount);
}


@end
