//
// BXObjCPair.h
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

#import <Foundation/Foundation.h>


#if defined(__cplusplus)
#import <BaseTen/BXObjCPtr.h>

namespace BaseTen
{
	template <typename T, typename U>
	struct ObjCPair
	{
		ObjCPtr <T> first;
		ObjCPtr <U> second;
		
		explicit ObjCPair (T a, U b):
			first (a), second (b) {}
		
		ObjCPair (const ObjCPair& p):
			first (* p.first), second (* p.second) {}
		
		bool operator== (const ObjCPair <T, U> &other) const
		{
			return (first == other.first && second == other.second);
		}		
	};	
}


namespace std {
	
	namespace tr1 {
		
		template <typename T, typename U>
		struct hash <BaseTen::ObjCPair <T, U> > {
			
			std::size_t
			operator() (BaseTen::ObjCPair <T, U> const &val) const
			{
				return (val.first.hash () ^ val.second.hash ());
			}
		};
	}
}
#endif
