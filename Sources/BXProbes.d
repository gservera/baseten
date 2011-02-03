/*
 * BXProbes.d
 * BaseTen
 *
 * Copyright 2008-2010 Marko Karppinen & Co. LLC.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


provider BaseTen
{
	probe begin_fetch ();
	probe end_fetch (void* context, char* schema, char* table, long count);

	probe sent_rollback_transaction (void* connection, long status, char* name);
	probe sent_commit_transaction (void* connection, long status, char* name);
	probe sent_savepoint (void* connection, long status, char* name);
	probe sent_rollback_to_savepoint (void* connection, long status, char* name);
	
	probe begin_sleep_preparation ();
	probe end_sleep_preparation ();
	probe begin_wake_preparation ();
	probe end_wake_preparation ();	
	probe begin_exit_preparation ();
	probe end_exit_preparation ();
};
