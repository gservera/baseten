//
// BXLogger.m
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


#import "BXLogger.h"
#import "BXArraySize.h"
#import <dlfcn.h>
#import <unistd.h>
#import <sys/time.h>


enum BXLogLevel BXLogLevel = kBXLogLevelDebug;
static BOOL stAbortOnAssertionFailure = NO;
// If the log file will be larger than this amount of bytes then it'll be truncated
static const unsigned long long kLogFileMaxSize = 1024 * 1024;
// When the log file will be truncated, this amount of bytes will be left to the beginning of the file
static const unsigned long long kLogFileTruncateSize = 1024 * 128; 


#if ! (defined (TARGET_OS_IPHONE) && TARGET_OS_IPHONE)
static void TruncateLogFile (NSString *filePath)
{
	NSFileManager *fm = [[NSFileManager alloc] init];
	if ([fm fileExistsAtPath: filePath])
	{
		NSNumber *sizeAttr = nil;
		NSError *error = nil;
		if ([fm respondsToSelector: @selector (attributesOfItemAtPath:error:)])
			sizeAttr = [[fm attributesOfItemAtPath: filePath error: &error] objectForKey: NSFileSize];
		else
			sizeAttr = [[(id) fm fileAttributesAtPath: filePath traverseLink: NO] objectForKey: NSFileSize];
		
		if (sizeAttr)
		{
			unsigned long long fileSize = [sizeAttr unsignedLongLongValue];
			if (kLogFileMaxSize < fileSize)
			{
				NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath: filePath];
				[fileHandle seekToFileOffset: (fileSize - kLogFileTruncateSize)];
				NSData *dataToLeave = [fileHandle readDataToEndOfFile];
				
				[fileHandle seekToFileOffset: 0];
				[fileHandle writeData: dataToLeave];
				[fileHandle truncateFileAtOffset: kLogFileTruncateSize];
				[fileHandle synchronizeFile];
				[fileHandle closeFile];
			}
		}
		else if (error)
		{
			BXLogError (@"Couldn't get attributes of file at path '%@', error: '%@'.", filePath, error);
		}
		else
		{
			BXLogError (@"Couldn't get attributes of file at path '%@'.", filePath);
		}
	}	
	[fm release];
}
#endif


static inline
const char* LogLevel (enum BXLogLevel level)
{
	const char* retval = NULL;
	switch (level)
	{
		case kBXLogLevelDebug:
			retval = "DEBUG:";
			break;
		
		case kBXLogLevelInfo:
			retval = "INFO:";
			break;
		
		case kBXLogLevelWarning:
			retval = "WARNING:";
			break;
			
		case kBXLogLevelError:
			retval = "ERROR:";
			break;
		
		case kBXLogLevelOff:
		case kBXLogLevelFatal:
		default:
			retval = "FATAL:";
			break;
	}
	return retval;
}


static inline
const char* LastPathComponent (const char* path)
{
	const char* retval = ((strrchr (path, '/') ?: path - 1) + 1);
	return retval;
}


static char*
CopyLibraryName (const void *addr)
{
	Dl_info info = {};
	char *retval = NULL;
	if (dladdr (addr, &info))
		retval = strdup (LastPathComponent (info.dli_fname));
	return retval;
}


static char*
CopyExecutableName ()
{
	uint32_t pathLength = 0;
	_NSGetExecutablePath (NULL, &pathLength);
	char* path = malloc (pathLength);
	char* retval = NULL;
	if (path)
	{
		if (0 == _NSGetExecutablePath (path, &pathLength))
			retval = strdup (LastPathComponent (path));

		free (path);
	}
	return retval;
}


#if ! (defined (TARGET_OS_IPHONE) && TARGET_OS_IPHONE)
void BXLogSetLogFile (NSBundle *bundle) {
    NSURL *baseURL = [NSURL fileURLWithPath:[@"~/Library/Logs" stringByStandardizingPath]];
    CFStringRef logsFolder = CFURLCopyFileSystemPath((CFURLRef)baseURL, kCFURLPOSIXPathStyle);
    NSString *bundleName = [bundle objectForInfoDictionaryKey: (NSString *) kCFBundleNameKey];
    NSString *logPath = [NSString stringWithFormat: @"%@/%@.%@", logsFolder, bundleName, @"log"];
    
    if (freopen ([logPath fileSystemRepresentation], "a", stderr)) {
        TruncateLogFile (logPath);
    } else {
        BXLogError (@"Couldn't redirect stderr stream to file at path '%@', errno: %d, error: '%s'.",
                    logPath, errno, strerror (errno));
    }
    
    if (logsFolder)
        CFRelease (logsFolder);
}
#endif


void BXSetLogLevel (enum BXLogLevel level)
{
	BXDeprecationLog ();
	BXLogLevel = level;
}


void BXLogSetLevel (enum BXLogLevel level)
{
	BXLogLevel = level;
}


void BXLogSetAbortsOnAssertionFailure (BOOL flag)
{
	stAbortOnAssertionFailure = flag;
}


void
BXAssertionDebug ()
{
	if (stAbortOnAssertionFailure)
		abort ();
	else
		BXLogError (@"Break on BXAssertionDebug to inspect.");
}


void
BXDeprecationWarning ()
{
	BXLogWarning (@"Break on BXDeprecationWarning to inspect.");
}


void
BXLog (const char *fileName, const char *functionName, const void *functionAddress, int line, enum BXLogLevel level, NSString * const messageFmt, ...)
{
	va_list args;
    va_start (args, messageFmt);
	BXLog_v (fileName, functionName, functionAddress, line, level, messageFmt, args);
	va_end (args);
}


void
BXLog_v (char const *fileName, char const *functionName, void const *functionAddress, int line, enum BXLogLevel level, NSString * const messageFmt, va_list args)
{
	char dateBuffer [32] = {};
	struct timeval tv = {};
	struct tm tm = {};
	gettimeofday (&tv, NULL);
	gmtime_r (&tv.tv_sec, &tm);
	strftime (dateBuffer, BXArraySize (dateBuffer), "%Y-%m-%d %H:%M:%S", &tm);
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	char *executable = CopyExecutableName ();
	char *library = CopyLibraryName (functionAddress);
	const char *file = LastPathComponent (fileName);
	const char isMain = ([NSThread isMainThread] ? 'm' : 's');
	
	NSString *message = [[[NSString alloc] initWithFormat: messageFmt arguments: args] autorelease];
	fprintf (stderr, "%19s.%.lf %s (%s) [%d %p%c]  %s:%d  %s \t%8s %s\n", 
		dateBuffer, 1000.0 * tv.tv_usec, executable, library ?: "???", getpid (), [NSThread currentThread], isMain, file, line, functionName, LogLevel (level), [message UTF8String]);
	fflush (stderr);
	
	//For GC.
	[message self];
	
	if (executable)
		free (executable);
	if (library)
		free (library);
	[pool drain];
}
