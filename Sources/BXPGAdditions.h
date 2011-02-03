//
// BXPGAdditions.h
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

#import <Foundation/Foundation.h>
#import "PGTS.h"
#import "BXPGExpressionVisitor.h"
#import "BaseTen.h"
#import "BXLogger.h"

@interface BXPropertyDescription (BXPGInterfaceAdditions)
- (void) BXPGVisitKeyPathComponent: (id <BXPGExpressionVisitor>) visitor;
@end


//FIXME: perhaps we could replace the name methods with something more easily understandable?
@interface NSObject (BXPGAdditions)
- (NSString *) BXPGEscapedName: (PGTSConnection *) connection;
@end


@interface BXEntityDescription (BXPGInterfaceAdditions)
- (NSString *) BXPGQualifiedName: (PGTSConnection *) connection;
@end


@interface BXAttributeDescription (BXPGInterfaceAdditions)
- (NSString *) BXPGQualifiedName: (PGTSConnection *) connection;
@end


@interface NSURL (BXPGInterfaceAdditions)
- (NSMutableDictionary *) BXPGConnectionDictionary;
@end
