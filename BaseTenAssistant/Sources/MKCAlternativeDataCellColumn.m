//
// MKCAlternativeDataCellColumn.m
// BaseTen Setup
//
// Copyright 2008-2009 Marko Karppinen & Co. LLC.
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

#import "MKCAlternativeDataCellColumn.h"

@interface NSObject (MKCAlternativeDataCellColumnAdditions)
- (id) MKCTableView: (NSTableView *) tableView 
  dataCellForColumn: (MKCAlternativeDataCellColumn *) aColumn
                row: (int) rowIndex
			current: (NSCell *) aCell;
@end


@implementation MKCAlternativeDataCellColumn

- (id) dataCellForRow: (NSInteger) rowIndex
{
    id retval = nil;
    if (-1 == rowIndex)
        retval = [super dataCell];
    else
    {
        id tableView = [self tableView];
		NSCell* currentCell = [super dataCellForRow: rowIndex];
        retval = [(id)[tableView delegate] MKCTableView: tableView dataCellForColumn: self row: rowIndex current: currentCell];
        if (nil == retval)
            retval = currentCell;
    }
    return retval;
}

@end
