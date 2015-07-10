//
// PGTSDeleteRule.m
// BaseTen
//
// Copyright 2006-2008 Marko Karppinen & Co. LLC.
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

#import "PGTSDeleteRule.h"
#import "PGTSConstants.h"

enum PGTSDeleteRule
PGTSDeleteRule (const unichar rule)
{
	enum PGTSDeleteRule deleteRule = kPGTSDeleteRuleUnknown;
	switch (rule)
	{
		case ' ':
			deleteRule = kPGTSDeleteRuleNone;
			break;
			
		case 'c':
			deleteRule = kPGTSDeleteRuleCascade;
			break;
			
		case 'n':
			deleteRule = kPGTSDeleteRuleSetNull;
			break;
			
		case 'd':
			deleteRule = kPGTSDeleteRuleSetDefault;
			break;
			
		case 'r':
			deleteRule = kPGTSDeleteRuleRestrict;
			break;
			
		case 'a':
			deleteRule = kPGTSDeleteRuleNone;
			break;
			
		default:
			deleteRule = kPGTSDeleteRuleUnknown;
			break;
	}	
	
	return deleteRule;
}
