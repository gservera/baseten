BaseTen Framework
======================================================

This is a fork of MK&C's BaseTen framework for using postgresql like CoreData 
http://basetenframework.org

Original source files can be found at BitBucket: https://bitbucket.org/mka/baseten

### About this repository

The main objective of this repository is to create a start point to continue working on 
this great framework for using PostgreSQL like Core Data, both on OS X and iOS, since the
original repository seems to have been inactive for a long time.

### What has been changed so far

* Deployment targets are now iOS 8.0 and OS X 10.8.
* Both BaseTen and BaseTenAppKit frameworks build and run successfully on OS X.
* Support for PostgreSQL 9 (tested with 9.3.4)
* Upgraded Xcode project configurations to have more modern settings and compile without warnings on Xcode 6.0
* Disabled Garbage Collection (the idea is to transition to ARC in the future)
* Replaced the PostgreSQL-universal and PostgreSQL-arm targets with a version of libpq.framework (https://github.com/spacialdb/libpq.framework) which already includes the PostgreSQL patches found at ./Patches in the original repo.

### How to build BaseTen and BaseTen AppKit

1. Build OpenSSL libraries (this is required only once) for libpq. To do so:

```
cd ./Contrib/libpq
sh ./build-libssl.sh
```

2. Compile using Xcode or create a release DMG containing the frameworks ready to be used, using these commands:

```
cd ./Tools/ReleaseDMG/
sh ./create_release_dmg.sh --without-latex
```

### What does not work yet

* Documentation: The included one is OK, but we should create a quick start guide or tutorial to easily begin working with BaseTen Framework.
* Unit Tests. I've tried to rewrite the original ones (found at ./Unit Tests) to make them use XCTest and modern test technologies. There are some of them already included in the main Xcode project, but there still are many of them which haven't been included yet, that's why the old "Unit Tests.xcodeproj" and related source files remain there. Please see Issues for more info on this.
* iOS compatibility has not been tested yet.
* There might be some license-related issues, I've done my best to do the right thing with them, but please notify me (or feel free to include what's missing) if there is something wrong or missing with licenses and/or copyright notices.

### How to participate

The Issue Tracker is the preferred way to file bug reports, add feature requests and create new pull requests, so feel free to add the issues that you detect.

### Licensing

This software is licensed under the Apache License (see the original repo)
