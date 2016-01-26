---
comments: true
date: 2015-01-21 19:46:53+00:00
slug: darwinup-apples-darwin-update-utility
title: darwinup, Apple's Darwin Update utility
wordpress_id: 880
tags:
- DarwinBuild
- darwinup
- NetBoot
---

Yesterday in [##osx-server](https://botbot.me/freenode/osx-server/), [Pepijn Bruienne](https://twitter.com/bruienne) mentioned having stumbled upon an OS X system binary he'd never seen before, which was new to me as well: `darwinup`. This tool is used (or _was_ used - public development of it seems to have stopped around OS X 10.7) for the purpose of managing versions of OS X system components by installing "roots" distributed in a variety of ways. It abstracts several different archive formats and wraps tools like curl, tar, rsync to perform its tasks.

It can install and remove packages installed via rsync-able locations and HTTP(S) URLs, and keeps track (in an SQLite database) of its activity and overwritten files such that it can roll back installations of system components to previous versions. I've seen it included on OS X systems as far back as OS X 10.7 (Lion) up through 10.10 (Yosemite). My immediate reaction was that this was like a basic package manager that's included with every copy of OS X.

Digging a bit further, this tool is part of the [DarwinBuild project](http://darwinbuild.macosforge.org/), whose public development seems to have stopped around 10.6/10.7 (like most other [macosforge](http://www.macosforge.org/) projects). According to their [notes](http://darwinbuild.macosforge.org/trac/browser/trunk/darwinup/NOTES), it is definitely _not_ a package manager, however. These notes contain a much more thorough explanation of the tool than its [manpage](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/darwinup.1.html), so I'd encourage you to read through it if you're interested in why the tool exists. The manpage has a few useful examples, such as installing components from Apple's (similarly-abandoned) [Roots repository](http://src.macosforge.org/Roots). This repo of compiled OS X components was also completely news to me.

The `darwinup` tool obviously exists for testing and development purposes, so I would highly _not recommend_ installing Apple's old roots onto a system you care about, because they are now so outdated and could overwrite critical system components with incompatible versions. Of course, you can always roll back..

Here's an example of installing compiled [bootp tools](http://www.opensource.apple.com/source/bootp/bootp-298/) from 10.7.2. You can also add additional `-v` options to print out more details about exactly what it's doing with network and files-on-disk activity.

```
$ sudo darwinup install http://src.macosforge.org/Roots/11C74/bootp.root.tar.gz

A /AppleInternal
A /AppleInternal/Developer
A /AppleInternal/Developer/Headers
A /AppleInternal/Developer/Headers/BSDPClient
A /AppleInternal/Developer/Headers/BSDPClient/BSDPClient.h
A /AppleInternal/Developer/Headers/DHCPServer
A /AppleInternal/Developer/Headers/DHCPServer/DHCPServer.h
  /System
  /System/Library
  /System/Library/LaunchDaemons
  /System/Library/LaunchDaemons/bootps.plist
  /System/Library/SystemConfiguration
  /System/Library/SystemConfiguration/IPConfiguration.bundle
  /System/Library/SystemConfiguration/IPConfiguration.bundle/Contents
U /System/Library/SystemConfiguration/IPConfiguration.bundle/Contents/Info.plist
  /System/Library/SystemConfiguration/IPConfiguration.bundle/Contents/MacOS
U /System/Library/SystemConfiguration/IPConfiguration.bundle/Contents/MacOS/IPConfiguration
  /System/Library/SystemConfiguration/IPConfiguration.bundle/Contents/Resources
  /System/Library/SystemConfiguration/IPConfiguration.bundle/Contents/Resources/English.lproj
U /System/Library/SystemConfiguration/IPConfiguration.bundle/Contents/Resources/English.lproj/Localizable.strings
  /usr
  /usr/lib
U /usr/lib/libBSDPClient.A.dylib
  /usr/lib/libBSDPClient.dylib
U /usr/lib/libDHCPServer.A.dylib
  /usr/lib/libDHCPServer.dylib
  /usr/libexec
U /usr/libexec/bootpd
  /usr/local
  /usr/local/bin
A /usr/local/bin/bsdpc
A /usr/local/darwinbuild
A /usr/local/darwinbuild/receipts
A /usr/local/darwinbuild/receipts/bootp
A /usr/local/darwinbuild/receipts/fb5424a830958c1b4cc8191de7b8c6e9d31f1aaf
  /usr/sbin
U /usr/sbin/ipconfig
  /usr/share
  /usr/share/man
  /usr/share/man/man5
  /usr/share/man/man5/bootptab.5
  /usr/share/man/man8
  /usr/share/man/man8/bootpd.8
U /usr/share/man/man8/ipconfig.8
Installed archive: 2 bootp.root.tar.gz 
9C140C50-A30E-453D-8F66-01207F4539A8

$ sudo darwinup list

Serial UUID                                  Date          Build    Name
====== ====================================  ============  =======  =================
2      17FEFDD5-E202-485A-B429-E5407881A845  Jan 21 11:33  13F34    bootp.root.tar.gz
```

Note that the build number is _not_ that of the root that was installed, it's the build of the currently-running system (10.9.5).

Now let's run the `bsdpc` utility that was just installed into `/usr/local/bin` to display info about available NetBoot images:

```
$ sudo bsdpc
Discovering NetBoot servers...

NetBoot Image List:
   1. DeployStudio-10.10-1.6.12 [Mac OS X Server] [Install] [Default]
```

Again, use this with care. We can see that these bootp tools installed system components in addition to executable binaries (from a 10.7 system onto a 10.9 system), so this is just a demonstration of the capabilities of `darwinup`. [Don't do this at home!](http://arstechnica.com/apple/2015/01/why-dns-in-os-x-10-10-is-broken-and-what-you-can-do-to-fix-it/)
