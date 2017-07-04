---
date: 2013-02-02T20:22:30Z
slug: monitoring-apples-xprotect-meta-feed-for-changes
tags:
- java
- plugin blacklist
- vendor metadata
- xprotect
title: 'Monitoring Apple''s XProtect meta feed for changes '

wordpress_id: 342
---

<!-- [![java-webstart_256.png](images/2013/02/java-webstart_256.png)](images/2013/02/java-webstart_256.png) -->

Greg had an [interesting blog post](http://managingosx.wordpress.com/2013/02/01/more-thoughts-on-xprotect-updater/) yesterday on handling Apple's XProtect Updater mechanism for managed environments, as admins were still scrambling to resolve clients that suddenly had their Java Web Plugin disabled and no newer version available to install that would satisfy Apple's minimum version requirements defined in its XProtect blacklist (new versions of [Java 6 from Apple](http://support.apple.com/kb/DL1573) for OS X 10.6 and [Java 7 from Oracle](http://www.oracle.com/technetwork/java/javase/downloads/jre7-downloads-1880261.html) have since been posted).

Maybe you'd like to at the very least know when this has been updated, and what are the nature of the changes. Here's another example where the `strings` command proves useful, and it's quickly obvious what's going on.

If we look in `/System/Library/LaunchDaemons` for something related to XProtect, we find `com.apple.xprotectupdater.plist`. Opening it, we see it simply runs the executable at `/usr/libexec/XProtectUpdater` every 86400 seconds (or 24 hours).

Now, run the `strings` command on this binary, and see a few telltale methods and values (this is taken from somewhere in the middle):

```
http://configuration.apple.com/configurations/macosx/xprotect/2/clientConfiguration.plist
/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.meta.plist
Version
LastModification
FetchURL
StartInterval
VPROC_GSK_START_INTERVAL change failed: %lu
SCNetworkReachabilityCreateWithName failed: %s
SCNetworkReachabilitySetCallback failed: %s
SCNetworkReachabilityScheduleWithRunLoop failed: %s
If-Modified-Since
NSURLConnection error: %@
Unexpected status code: %ld
Unable to verify signature: %@
meta
Ignoring new signature plist: Not an increase in version
Last-Modified
EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'
Last-modified date is later in time than current date
```

Taking note of the URL at the top, we can simply `curl` this URL to see that it's nothing more than a plaintext XML plist prepended with a security signature (the same signature that's getting written to `XProtect.meta.plist`. Looking at the other strings, it's clear that it's using the Last-Modified HTTP header to compare this date with the current system date ("Last-modified date is later in time than current date"). It's also using the `Version` key in the plist to determine whether the plist available from Apple is more recent than the one already installed.

Note, the "2" in the URL `..xprotect/2/clientConfiguration.plist` is what was returned on my Lion machine. Snow Leopard clients look for "1", Mountain Lion clients look for "3", and so on.

Now we can throw this plist URL into a site like [ChangeDetection.com](https://www.changedetection.com/), and ask it to check this URL once per day and send us an e-mail if it's changed. We can see the details on the change, and when it was last modified. **Update:** Given that Apple's updated this list within hours of new Flash/Java releases and will probably continue to do so, checking daily is probably not frequent enough.

We could also use an application like [Jenkins](http://jenkins-ci.org),  that already handles polling, jobs, and notifications. The [URLTrigger](https://wiki.jenkins-ci.org/display/JENKINS/URLTrigger+Plugin) works well for this, and we can simply ask it to track the last modified date of the URL however frequently we'd like, up to the minute if we so wish. From this point on we could write the `XProtect.meta.plist` file ourselves, package it and automatically push it to test clients, or anything we could dream up.

If we want to extract more information, we can also write a very simple script to do so, put it into a versioning system along with the `PluginBlacklist` information, etc. This example just prints out the version of the meta plist:

```bash
URL=http://configuration.apple.com/configurations/macosx/xprotect/2/clientConfiguration.plist
curl -s $URL | awk '/\<\?xml/{i++}i' > /tmp/meta.plist
/usr/libexec/PlistBuddy -c 'Print :meta:Version' /tmp/meta.plist
```

Lots of ways to solve a trivial problem! I'm not advocating whether or not to take measures to disable the XProtect mechanism on all your managed clients, but this might at least give some ideas on how you can at least be kept up to date with Apple's new minimum security requirements for plugins, known malware, and anything  else Apple will add to XProtect in the future.
