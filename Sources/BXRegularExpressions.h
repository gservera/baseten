//
// BXRegularExpressions.h
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


#import <BaseTen/pcre.h>
#import <BaseTen/BXExport.h>
#import <Foundation/Foundation.h>


struct bx_regular_expression_st 
{
	pcre *re_expression;
	pcre_extra *re_extra;
	char *re_pattern;
};


BX_EXPORT int BXREExec (struct bx_regular_expression_st *re, NSString *subject, int options, int *ovector, int ovectorSize);
BX_EXPORT NSString *BXRESubstring (struct bx_regular_expression_st *re, NSString *inSubject, int idx, int *ovector, int ovectorSize);
BX_EXPORT void BXRECompile (struct bx_regular_expression_st *re, char const * const pattern);
BX_EXPORT void BXREFree (struct bx_regular_expression_st *re);
