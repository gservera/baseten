//
// BXExport.h
// BaseTen
//
// Copyright 2008-2010 Marko Karppinen & Co. LLC.
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


#ifndef BX_INTERNAL
#ifdef __cplusplus
#define BX_INTERNAL extern "C" __attribute__((visibility("hidden")))
#else
#define BX_INTERNAL extern     __attribute__((visibility("hidden")))
#endif
#endif


#ifndef BX_EXPORT
#ifdef __cplusplus
#define BX_EXPORT extern "C"   __attribute__((visibility("default")))
#else
#define BX_EXPORT extern       __attribute__((visibility("default")))
#endif
#endif


#ifndef BX_ANALYZER_NORETURN
#if __clang__
#define BX_ANALYZER_NORETURN   __attribute__((analyzer_noreturn))
#else
#define BX_ANALYZER_NORETURN
#endif
#endif


#ifndef BX_FORMAT_FUNCTION
#ifdef NS_FORMAT_FUNCTION
#define BX_FORMAT_FUNCTION(X,Y) NS_FORMAT_FUNCTION(X,Y)
#else
#define BX_FORMAT_FUNCTION(X,Y)
#endif
#endif


#ifndef BX_DEPRECATED_IN_1_8
#define BX_DEPRECATED_IN_1_8 DEPRECATED_ATTRIBUTE
#endif
