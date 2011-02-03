//
// BXInvocation.m
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

#import "BXInvocation.h"


@implementation BXInvocation

+ (id) invocationWithInvocation: (NSInvocation *) anInvocation
{
    id rval = [[[self alloc] init] autorelease];
    [rval setInvocation: anInvocation];
    return rval;
}

- (id) init
{
    return self;
}

- (void) dealloc
{
    [invocation release];
    [super dealloc];
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL) aSelector
{
    return [NSInvocation instanceMethodSignatureForSelector: aSelector];
}

- (void) forwardInvocation: (NSInvocation *) anInvocation
{
    [anInvocation invokeWithTarget: invocation];
}

- (id) target
{
    return persistentTarget;
}

- (void) setTarget: (id) anObject
{
    persistentTarget = anObject;
}

- (void) invoke
{
    [invocation invokeWithTarget: persistentTarget];
}

- (void) setInvocation: (NSInvocation *) anInvocation
{
    if (invocation != anInvocation) 
    {
        [invocation release];
        invocation = [anInvocation retain];
        
        [self setTarget: [invocation target]];
        [invocation setTarget: nil];
    }
}

@end
