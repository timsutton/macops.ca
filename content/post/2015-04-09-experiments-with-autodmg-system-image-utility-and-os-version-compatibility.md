---
comments: false
date: 2015-04-09T14:05:09Z
slug: experiments-with-autodmg-system-image-utility-and-os-version-compatibility
tags:
- AutoDMG
- Automator
- dtrace
- Installer
- System Image Utility
title: Experiments with AutoDMG, System Image Utility and OS version compatibility

wordpress_id: 930
---

<!-- [![SystemImageUtility_128.png](images/2015/04/SystemImageUtility_128.png)](images/2015/04/SystemImageUtility_128.png) -->

I use [AutoDMG](https://github.com/MagerValp/AutoDMG) to build restorable system images for OS X, which uses a technique similar to System Image Utility's NetRestore: run the OS X installer on one machine, but targeted at a disk image which is later converted to a read-only disk image, which can be restored to a Mac.

While running the 10.10.3 developer seeds on my build machine I noticed my AutoDMG builds seemed to never complete. After looking more closely at what processes were running, I noticed a suspicious process: `/System/Library/Frameworks/Automator.framework/Versions/A/Support/update_automator_cache --system --force`, which was called by a postinstall script in the `com.apple.pkg.Essentials` package. The process wasn't actually hung - upon inspection using the [`opensnoop`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/opensnoop.1m.html) DTrace script, it was continuously re-indexing Automator bundles in an infinite loop.

Sometimes postinstall scripts have issues because there is a missing `"$3"` in a path, which would be substituted in with the target volume path. In my case, maybe this was just an issue with the beta version of the Automator framework. Here, the `update_automator_cache` process that's trying to cache Automator bundles was the 10.10.3 seed version, not the 10.10.2 version that was actually being installed. It runs, however, [chrooted](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man2/chroot.2.html) in the volume being installed to, meaning it's acting as though the installation volume is its root filesystem.

Because the issue seemed to be with this particular context of the OS installer, System Image Utility's NetRestore image creation workflow exhibited the same issue. So, I [filed a bug](http://www.openradar.me/radar?id=5241812365082624), but Apple closed it immediately due to my combining 10.10.3 tools with a 10.10.2 installer, which they claimed was unsupported. Of course, at the time there was no 10.10.3 installer available.

Yesterday (April 8, 2014) 10.10.3 [was released](https://support.apple.com/en-us/HT204490), and I'm no longer able to reproduce the issue, and I was also able to still build a 10.10.2 image on a 10.10.3 host. Allister Banks gave some additional data yesterday, which was that he experienced the same looping process when building a 10.10.3 image from a 10.10.2 host.

What's interesting is that Apple also just released a [KB article](https://support.apple.com/en-us/HT204654) which seems to detail my issue exactly in a succinct summary. They recommend always using the most recent version available, for "best results." However the difference here is that they claim a 10.10.3 host can build "10.10.2 and earlier." So the response I got in my radar might be not entirely accurate, but this is also confused by the fact that my earlier test was using the developer seed and not a released version.

My own summary is that while there might be aspects of SIU that change from minor releases, and that building an image from an installer source should usually work, if there are issues because of a bug in a tool that's run in a postinstall script, or due to an incompatibility with versions of system frameworks being used in this context, there's not much one can do except wait until the update is generally available and a new OS installer is available in the Mac App Store.
