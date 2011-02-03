//
// BXDataModelCompiler.m
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


#import "BXDataModelCompiler.h"
#import "BXLogger.h"
#import "BXEnumerate.h"
#import "BXArraySize.h"



@implementation BXDataModelCompiler
+ (NSString *) momcPath
{
	__strong static NSString* momcPath = nil;
	if (! momcPath)
	{
		NSFileManager* manager = [NSFileManager defaultManager];
		
		//Paths inside the system developer directory which may lead to momc.
		NSArray* developerSubpaths = [NSArray arrayWithObjects: 
									  @"/usr/bin/momc", 
									  @"/Library/Xcode/Plug-ins/XDCoreDataModel.xdplugin/Contents/Resources/momc", 
									  nil];
		
		
		//Try using xcode-select's setting.
		{
			int fd = open ("/usr/share/xcode-select/xcode_dir_path", O_RDONLY | O_SHLOCK);
			FILE* file = fdopen (fd, "r");
			if (file)
			{
				char buffer [1024] = {};
				if (fgets (buffer, BXArraySize (buffer), file))
				{
					//Remove the newline character if one exists.
					size_t length = strlen (buffer);
					if ('\n' == buffer [length - 1])
						buffer [length - 1] = '\0';
					
					BXEnumerate (currentSubpath, e, [developerSubpaths objectEnumerator])
					{
						NSString* path = [NSString stringWithFormat: @"%s%@", buffer, currentSubpath];
						if ([manager fileExistsAtPath: path])
						{
							momcPath = [path retain];
							fclose (file);
							goto end;
						}
					}
				}
			}
			fclose (file);
		}
		
		//Try using paths from NSSearchPathForDirectoriesInDomains 
		//(which returns always /Developer and not xcode-select's setting).
		{
			NSArray* paths = NSSearchPathForDirectoriesInDomains (NSDeveloperDirectory, NSAllDomainsMask, YES);
			BXEnumerate (currentPath, e, [paths objectEnumerator])
			{
				BXEnumerate (currentSubpath, e, [developerSubpaths objectEnumerator])
				{
					NSString* path = [currentPath stringByAppendingString: currentSubpath];
					if ([manager fileExistsAtPath: path])
					{
						momcPath = [path retain];
						goto end;
					}
				}
			}
		}
		
		//Finally try something rather old.
		{
			NSString* path = @"/Library/Application Support/Apple/Developer Tools/Plug-ins/XDCoreDataModel.xdplugin/Contents/Resources/momc";
			if ([manager fileExistsAtPath: path])
			{
				momcPath = [path retain];
				goto end;
			}
		}
	}
end:
	return momcPath;
}


- (void) dealloc
{
	[mModelURL release];
	[mCompiledModelURL release];
	[mMomcTask release];
	[mErrorPipe release];
	[super dealloc];
}


- (void) setDelegate: (id <BXDataModelCompilerDelegate>) anObject
{
	mDelegate = anObject;
}


- (void) setModelURL: (NSURL *) aFileURL
{
	if (mModelURL != aFileURL)
	{
		[mModelURL release];
		mModelURL = [aFileURL retain];
	}
}


- (void) setCompiledModelURL: (NSURL *) aFileURL
{
	if (mCompiledModelURL != aFileURL)
	{
		[mCompiledModelURL release];
		mCompiledModelURL = [aFileURL retain];
	}
}


- (NSURL *) compiledModelURL
{
	return mCompiledModelURL;
}


- (void) waitForCompletion
{
	[mMomcTask waitUntilExit];
}


- (void) momcTaskFinished: (NSNotification *) notification
{
	[mDelegate dataModelCompiler: self finished: [mMomcTask terminationStatus] errorOutput: [mErrorPipe fileHandleForReading]];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[mMomcTask release];
	mMomcTask = nil;
	[mErrorPipe release];
	mErrorPipe = nil;
}


- (void) compileDataModel
{	
	NSString* sourcePath = [mModelURL path];
	char* pathFormat = NULL;
	if ([sourcePath hasSuffix: @".xcdatamodeld"])
	{
		asprintf (&pathFormat, "%s/BaseTen.datamodel.%u.XXXXX", 
				  [NSTemporaryDirectory () UTF8String], getpid ());
		if (! pathFormat)
		{
			BXLogError (@"asprintf returned NULL. errno was %d.", errno);
			goto bail;
		}
		
		if (! mkdtemp (pathFormat))
		{
			BXLogError (@"mkdtemp returned NULL. errno was %d.", errno);
			goto bail;
		}
	}
	else
	{
		asprintf (&pathFormat, "%s/BaseTen.datamodel.%u.XXXXX.mom", 
				  [NSTemporaryDirectory () UTF8String], getpid ());
		if (! pathFormat)
		{
			BXLogError (@"asprintf returned NULL.");
			goto bail;
		}
		
		if (-1 == mkstemps (pathFormat, 5))
		{
			BXLogError (@"mkstemps returned -1. errno was %d.", errno);
			goto bail;
		}
	}
	
	NSString* targetPath = [NSString stringWithCString: pathFormat encoding: NSUTF8StringEncoding];
	NSString* momcPath = [[self class] momcPath];
	NSArray* arguments = [NSArray arrayWithObjects: sourcePath, targetPath, nil];
	[self setCompiledModelURL: [NSURL fileURLWithPath: targetPath]];
	mErrorPipe = [[NSPipe pipe] retain];
	
	mMomcTask = [[NSTask alloc] init];
	[mMomcTask setLaunchPath: momcPath];
	[mMomcTask setArguments: arguments];
	[mMomcTask setStandardError: [mErrorPipe fileHandleForWriting]];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector (momcTaskFinished:) 
												 name: NSTaskDidTerminateNotification object: mMomcTask];
	[mMomcTask launch];
	
bail:
	if (pathFormat)
		free (pathFormat);
}
@end
