//
// BXObjectStatusInfo.m
// BaseTen
//
// Copyright 2008 Marko Karppinen & Co. LLC.
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

#import "BXObjectStatusInfo.h"
#import "BXDatabaseObject.h"
#import "BXDatabaseObjectPrivate.h"


/**
 * \brief A proxy for retrieving database object status.
 * \see ValueTransformers
 * \ingroup baseten
 */
@implementation BXObjectStatusInfo

+ (id) statusInfoWithTarget: (BXDatabaseObject *) target
{
    return [[[[self class] alloc] initWithTarget: target] autorelease];
}

- (id) initWithTarget: (BXDatabaseObject *) target
{
    checker = [[NSProtocolChecker alloc] initWithTarget: target protocol: @protocol (BXObjectStatusInfo)];
    return self;
}

- (void) dealloc
{
    [checker release];
    [super dealloc];
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL) aSelector
{
    return [checker methodSignatureForSelector: aSelector];
}

- (void) forwardInvocation: (NSInvocation *) anInvocation
{
    [anInvocation invokeWithTarget: checker];
}

- (void) addObserver: (NSObject *) anObserver forKeyPath: (NSString *) keyPath 
             options: (NSKeyValueObservingOptions) options context: (void *) context
{
    [[checker target] addObserver: anObserver forKeyPath: @"statusInfo" options: options context: context];
}

- (void) removeObserver: (NSObject *) anObserver forKeyPath: (NSString *) keyPath
{
    [[checker target] removeObserver: anObserver forKeyPath: @"statusInfo"];
}

- (NSNumber *) unlocked
{
    return [NSNumber numberWithBool: ![(id) [checker target] isLockedForKey: nil]];
}

//We have to implement this by hand since this is an NSProxy.
- (id) valueForKeyPath: (NSString *) keyPath
{
    id rval = nil;
    if (NSNotFound == [keyPath rangeOfCharacterFromSet: 
        [NSCharacterSet characterSetWithCharactersInString: @"."]].location)
    {
        SEL selector = NSSelectorFromString (keyPath);
        if ([self respondsToSelector: selector])
            rval = [self performSelector: selector];
        else
            rval = [self valueForKey: keyPath];
    }
    else
    {
        [[NSException exceptionWithName: NSInternalInconsistencyException 
								 reason: [NSString stringWithFormat: @"Keypath shouldn't contain periods but was %@", keyPath]
                               userInfo: nil] raise];
    }
    return rval;
}

/** 
 * \brief Returns a status constant for the given key.
 *
 * The constant may then be passed to value transformers in BaseTenAppKit.
 * \param aKey An NSString that corresponds to a field name.
 * \return An NSValue that contains the constant.
 */
- (id) valueForKey: (NSString *) aKey
{
    enum BXObjectLockStatus rval = kBXObjectNoLockStatus;
    id target = [checker target];
    if ([target isDeleted] || [target lockedForDelete])
        rval = kBXObjectDeletedStatus;
    else if (([target isLockedForKey: aKey]))
        rval = kBXObjectLockedStatus;
    
    return [NSValue valueWithBytes: &rval objCType: @encode (enum BXObjectLockStatus)];
}
@end
