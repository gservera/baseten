//
//  BXDatabaseTestCase.m
//  BaseTen
//
//  Created by Guillem on 13/9/14.
//
//

#import "BXDatabaseTestCase.h"
#import <BaseTen/PGTSConstants.h>
#import <BaseTen/BXRelationshipDescriptionPrivate.h>
#import "BXSocketDescriptor.h"

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

- (void)invokeTest {
    NSLog(@"Running without GCD");
    [BXSocketDescriptor setUsesGCD:NO];
    [super invokeTest];
    NSLog(@"Running with GCD");
    [BXSocketDescriptor setUsesGCD:YES];
    [super invokeTest];
}

- (void)tearDown {
    [mContext disconnect];
    mContext = nil;
    mStorage = nil;
    [super tearDown];
}

#pragma mark - DB

- (NSURL *)databaseURI {
    return [NSURL URLWithString: @"pgsql://guillem@localhost/basetentest"];
}


- (NSDictionary *)connectionDictionary {
    return @{kPGTSHostKey : @"localhost",
             kPGTSUserNameKey : @"guillem",
             kPGTSDatabaseNameKey : @"basetentest",
             kPGTSSSLModeKey : @"disable"};
}

- (enum BXSSLMode)SSLModeForDatabaseContext: (BXDatabaseContext *)ctx {
    return kBXSSLModeDisable;
}

@end

@implementation BXDatabaseObject (UnitTestAdditions)
- (id) resolveNoncachedRelationshipNamed: (NSString *) aName
{
	NSError* error = nil;
	//BXDatabaseObject caches related objects so for testing purposes we need to fetch using the relationship.
	BXEntityDescription* entity = [[self objectID] entity];
	BXRelationshipDescription* rel = [[entity relationshipsByName] objectForKey: aName];
	id rval = [rel targetForObject: self error: &error];
	NSAssert (nil == error, [error description]);
	return rval;
}
@end