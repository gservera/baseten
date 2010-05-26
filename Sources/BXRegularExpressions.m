//
// BXRegularExpressions.m
// BaseTen
//
// Copyright (C) 2008-2010 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://www.karppinen.fi/baseten/licensing/ or by contacting
// us at sales@karppinen.fi. Without an additional license, this software
// may be distributed only in compliance with the GNU General Public License.
//
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License, version 2.0,
// as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
// $Id$
//


#import "BXRegularExpressions.h"
#import "BXLogger.h"


int
BXREExec (struct bx_regular_expression_st *re, NSString *inSubject, int options, int *ovector, int ovectorSize)
{
	char const * const subject = [inSubject UTF8String];
	int retval = pcre_exec (re->re_expression, re->re_extra, subject, strlen (subject), 0, options, ovector, ovectorSize);
	[inSubject self];
	return retval;
}


NSString *
BXRESubstring (struct bx_regular_expression_st *re, NSString *subject, int idx, int *ovector, int ovectorSize)
{
	NSString *retval = nil;
	char const *substring = NULL;
	int count = pcre_get_substring ([subject UTF8String], ovector, ovectorSize / 3, idx, &substring);
	if (0 < count)
	{
		retval = [[[NSString alloc] initWithBytesNoCopy: retval length: count encoding: NSUTF8StringEncoding freeWhenDone: YES] autorelease];
	}
	[subject self];
	return retval;
}


void
BXRECompile (struct bx_regular_expression_st *re, char const * const pattern)
{
	int const options = PCRE_UTF8 | PCRE_MULTILINE | PCRE_DOLLAR_ENDONLY;
	char const *error = NULL;
	int errorOffset = 0;
	if ((re->re_expression = pcre_compile (pattern, options, &error, &errorOffset, NULL)))
	{
		re->re_extra = pcre_study (re->re_expression, 0, &error);
		if (error)
		{
			BXLogError (@"Failed to study pattern '%s': %s", pattern, error);
			pcre_free (re->re_expression);
		}
		else
		{
			re->re_pattern = strdup (pattern);
		}
	}
	else
	{
		BXLogError (@"Failed to compile pattern at offset %d '%s': %s", errorOffset, pattern, error);
	}
}


void
BXREFree (struct bx_regular_expression_st *re)
{
	if (re)
	{
		if (re->re_expression)
		{
			pcre_free (re->re_expression);
			re->re_expression = NULL;
		}
		
		if (re->re_extra)
		{
			pcre_free (re->re_extra);
			re->re_extra = NULL;
		}
		
		if (re->re_pattern)
		{
			free (re->re_pattern);
			re->re_pattern = NULL;
		}
	}
}
