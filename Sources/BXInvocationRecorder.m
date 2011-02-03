//
// BXInvocationRecorder.m
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

#import "BXInvocationRecorder.h"
#import "BXInvocation.h"


/** \internal Records invocations the same way as NSUndoManager. */
@implementation BXInvocationRecorder

+ (id) recorder
{
    return [[[self alloc] init] autorelease];
}

- (id) init
{
    if ((self = [super init]))
    {
        recordedInvocations = [[NSMutableArray alloc] init];
        retainsArguments = YES;
        invocationsRetainTarget = YES;
    }
    return self;
}

- (void) dealloc
{
    [recordedInvocations release];
    [super dealloc];
}

/** 
 * \internal
 * Record an invocation.
 * \attention   Does NOT work with variable argument lists on i386.
 */
- (id) recordWithTarget: (id) anObject
{
    invocationsRetainTarget = YES;
    recordingTarget = anObject;
    return self;
}

/**
 * \internal
 * Record an invocation.
 * \attention   Does NOT work with variable argument lists on i386.
 * \param       anObject        An object that will not be retained.
 */
- (id) recordWithPersistentTarget: (id) anObject
{
    id rval = [self recordWithTarget: anObject];
    invocationsRetainTarget = NO;
    return rval;
}

- (NSInvocation *) recordedInvocation
{
    id rval = [recordedInvocations lastObject];
    [recordedInvocations removeLastObject];
    return rval;
}

- (NSArray *) recordedInvocations
{
    id rval = [[recordedInvocations copy] autorelease];
    [recordedInvocations removeAllObjects];
    return rval;
}

- (void) forwardInvocation: (NSInvocation *) invocation
{
    [invocation setTarget: recordingTarget];
    if (YES == retainsArguments)
    {
        if (NO == invocationsRetainTarget)
            invocation = [BXInvocation invocationWithInvocation: invocation];
        [invocation retainArguments];
    }
    [recordedInvocations addObject: invocation];
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL) aSelector
{
    NSMethodSignature* rval = nil;
#if 0
    //+[Class class] always returns self, right?
    if ([recordingTarget class] == recordingTarget)
        rval = [recordingTarget instanceMethodSignatureForSelector: aSelector];
    else
#endif
        rval = [recordingTarget methodSignatureForSelector: aSelector];
    return rval;
}

@end
