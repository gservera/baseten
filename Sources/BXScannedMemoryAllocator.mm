//
// BXScannedMemoryAllocator.mm
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

#import "BXScannedMemoryAllocator.h"


static BOOL 
IsCollectionEnabled ()
{
	BOOL retval = NO;
    //Symbol existence verification requires NULL != -like comparison.
	if (NULL != NSAllocateCollectable && [NSGarbageCollector defaultCollector])
		retval = YES;
	return retval;
}

BOOL BaseTen::ScannedMemoryAllocatorBase::collection_enabled = IsCollectionEnabled ();


void *
BaseTen::ScannedMemoryAllocatorBase::allocate (size_t size)
{
	void *retval = NULL;
	
#if defined (OBJC_NO_GC)
	retval = malloc (size);
#else
	if (BaseTen::ScannedMemoryAllocatorBase::collection_enabled)
		retval = NSAllocateCollectable (size, NSScannedOption);
	else
		retval = malloc (size);
#endif
	
	if (! retval)
		throw std::bad_alloc ();
	
	return retval;
}


void
BaseTen::ScannedMemoryAllocatorBase::deallocate (void *ptr)
{
#if defined (OBJC_NO_GC)
	free (ptr);
#else
	if (! BaseTen::ScannedMemoryAllocatorBase::collection_enabled)
		free (ptr);
#endif
}
