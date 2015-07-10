//
// ecpg_config.h
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

#if defined (__i386__) && __i386__
#include <BaseTen/postgresql/i386/ecpg_config.h>
#elif defined (__x86_64__) && __x86_64__
#include <BaseTen/postgresql/x86_64/ecpg_config.h>
#elif defined (__arm__) && __arm__
#include <BaseTen/postgresql/armv6/ecpg_config.h>
#else
#error "Unsupported architecture."
#endif
