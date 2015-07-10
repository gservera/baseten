//
// NSObject+BaseTenAdditions.h
// BaseTen
//
// Copyright 2010 Marko Karppinen & Co. LLC.
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


#if ! (defined (TARGET_OS_IPHONE) && TARGET_OS_IPHONE)
@interface NSPointerArray (BaseTenAdditions)
- (void) addObject: (id) anObject;
- (NSEnumerator *) objectEnumerator;
@end
#endif



#if ! (defined (TARGET_OS_IPHONE) && TARGET_OS_IPHONE)
@interface NSMapTable (BaseTenAdditions)
- (void) makeObjectsPerformSelector: (SEL) selector withObject: (id) object;
- (NSArray *) objectsForKeys: (NSArray *) keys notFoundMarker: (id) marker;
@end
#endif
