---
comments: true
date: 2013-02-25T01:11:38Z
slug: everything-youll-wish-you-didnt-know-about-disabling-java-7-updates
tags:
- deployment
- Disabling update checks
- java
- launchd
- Sparkle
title: Everything you'll wish you didn't know about disabling Java 7 updates

wordpress_id: 406
---

<!-- [![JavaCupLogo-161](images/2013/02/JavaCupLogo-161.png)](images/2013/02/JavaCupLogo-161.png) -->

Oracle's Java 7 JRE for OS X was first officially released in October 2012. As expected, there have been issues deploying and testing it, amidst confusion about Apple's Java 6 updates and it disabling symlinks to the web plugin, the pre-emptive disabling of Java with XProtect, and more.

And of course, the first thing administrators need to verify is that deployed software won't periodically nag the user to install an update that they don't have sufficient rights to install, or that they shouldn't install for other reasons. I'll cover a few ideas in this post specifically about the updater mechanisms and approaches to disabling it, and focus on other specific issues with this package in future posts.

<!--more-->



### deployment.properties a.k.a. com.oracle.javadeployment a.k.a. com.oracle.java.JavaAppletPlugin a.k.a. com.oracle.java.Java-Updater a.k.a. com.oracle.java.Helper-Tool



There is a place to disable update checks in the Java Control Panel:

{{< imgcap
  caption="Look! It unchecked the checkbox!"
  img="/images/2013/02/javacontrolpanel-updates@2x.png"
>}}

Java uses what's known as a "Java properties" format to store preferences, that looks similar to a .ini file. Many user preferences seem to touch a file at `/Library/Application Support/Oracle/Java/Deployment/deployment.properties`. This file's options are somewhat [documented](http://docs.oracle.com/javase/7/docs/technotes/guides/deployment/deployment-guide/properties.html).

In more recent versions, some settings (perhaps those known to have OS X-specific implementations, like the boolean `deployment.macosx.check.update`) seem to be stored instead in the defaults domain `com.oracle.javadeployment` in a Java-style namespace:


```xml
<key>/com/oracle/javadeployment/</key>
<dict>
  	<key>deployment.macosx.check.update</key>
  	<string>false</string>
   	<key>deployment.modified.timestamp</key>
   	<string>1361734949180</string>
   	<key>deployment.version</key>
   	<string>7.0</string>
</dict>
```



It doesn't actually matter for now where the `deployment.macosx.check.update` setting is actually stored, because it has no effect on whether or not Java 7 will check for updates.

**Update 13/03/15:** It [turns out](http://macops.ca/everything-youll-wish-you-didnt-know-about-disabling-java-7-updates/#comment-53) that this does have an effect, it controls the plugin's own built-in update checker, that I managed to never see while scrutinizing the Sparkle-based updater. So while it suppresses the nag when the plugin is actually invoked, it doesn't control the background update check mechanism that's detailed below and in a [related post](http://macops.ca/java-7-how-not-to-use-launchd-for-your-app/).

{{< imgcap
  img="/images/2013/02/java7_sparkle@2x.png"
>}}

There've been a [few](https://groups.google.com/d/topic/munki-dev/aDapiQcwu3o/discussion) [discussion](https://jamfnation.jamfsoftware.com/discussion.html?id=6489) [threads](https://jamfnation.jamfsoftware.com/discussion.html?id=6639) about configuring the update setting, but all these attempts seem to do is tell the Control Panel about the state of the checkbox, and not suppress the active checking (and prompting) for updates.


### The Java-Updater/Helper-Tool Yin-Yang of Doom

Briefly, here are the basic mechanisms of the update-checking system as it is now (here's the [launchd manpage](https://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man5/launchd.plist.5.html) for reference):

  * There is a LaunchDaemon (`com.oracle.java.Helper-Tool.plist`) and a LaunchAgent (`com.oracle.java.Java-Updater.plist`) installed in the usual place within `/Library`.
  * They are actually symlinks to the web plugin's installation area, in `/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Resources`.
  * The LaunchDaemon is not run on a schedule, but rather triggered by changes to the LaunchAgent plist file using a `WatchPaths` entry.
  * The LaunchDaemon runs `Helper-Tool`, a Bash script whose purpose is to enforce (based on default times set by an install script) or randomize the `StartCalendarInterval` key in the LaunchAgent plist, and reload the LaunchAgent. It modifies the file that triggers itself to run... to modify the file... that triggers it to run... you can probably see why this may not be a great idea.
  * The LaunchAgent runs the `Java Updater` binary located inside a .app bundle in the aforementioned `Resources` directory.
  * Java Updater.app is essentially a vessel for the [Sparkle updater framework](http://sparkle.andymatuschak.org/), which simply manually calls Sparkle's "check in background" function. It is a pure Cocoa app. It does not seem to have any link to the Java plugin, settings configurable via the control panel, etc. It is not linked to any Java library.


There are a several major issues with this LaunchAgent/Daemon combo that I'll cover in a future post.

For now, there are a couple possible workarounds I'd consider that are the least intrusive and most reliable way of suppressing the update check behavior. They each still have issues that are very important to understand if you want to deploy this and not dig yourself out of a hole later. I don't consider either of them acceptable in the long term, and can't recommend one over the other - it all depends on your environment.


### Neuter Sparkle

One approach is to leverage the configurability of Sparkle. Because Java Updater is directly invoking Sparkle's check method, overriding check behavior preference keys as outlined [here](https://github.com/andymatuschak/Sparkle/wiki/customization) won't help, as far as I can tell. If you can at least read some Objective-C code you can look at Sparkle's [SUUpdater.m](https://github.com/andymatuschak/Sparkle/blob/master/SUUpdater.m) and see for yourself what it does, and make a pretty good guess at what methods Java Updater is calling by inspecting its binary strings (hint: the `resetUpdateCycle` and `checkForUpdatesInBackground` methods).

Sparkle supports overriding some preference keys that would typically be defined in a bundle's `Info.plist` file, by setting them in the bundle's user defaults domain instead (at either the user or system level). In this case, we're looking at the `com.oracle.java.JavaAppletPlugin` domain, and the `SUFeedURL` string key. (It might be worth pointing out now that the Java 7 package uses about 4 different preference domains for the plugin and helpers, which doesn't make figuring these out any easier).

Setting `SUFeedURL` to an invalid URL like "nil" (or one that doesn't actually contain a Sparkle appcast feed) will cause Sparkle to [fail silently](https://github.com/andymatuschak/Sparkle/blob/master/SUUpdater.m#L334). It's worth noting, since this is being run as a LaunchAgent, that this doesn't cause the actual Java Updater app to fail with a non-zero exit code. As far as Java Updater is concerned, it's done its job and Sparkle just didn't have anything for it to do.

There are alternate, more desperate Sparkle-related tweaks possible that will yield similar results to the above, which will be in a future post.

**Advantages:** This preference key can be managed like any other: a `defaults` command writing the value to `/Library/Preferences/com.oracle.java.JavaAppletPlugin`, MCX, or a Configuration Profile. The preference can later be removed/changed if desired, and it's completely independent of the plugin installation.

**Disadvantages:** This overrides the update URL for anywhere the plugin may want to check for updates, meaning that if one checks the Control Panel manually for an update, it will not be able to check or verify whether it is up to date. It will state that it was last run whenever Java Updater was last run, but that it is "Unable to check for updates", and to "Please check your internet connection and try again." You're essentially removing the ability for the plugin to update itself via its built-in mechanisms, even the user- or support-initiated ones. This puts it roughly on par with the [state](http://managingosx.wordpress.com/2012/08/22/flash-mob/) of [deploying](http://managingosx.wordpress.com/2012/08/19/more-on-flash-player-11-3/) [Adobe Flash](http://managingosx.wordpress.com/2012/08/24/flash-dance).


### Remove (but don't disable) the LaunchAgent

A second approach is to prevent the LaunchAgent from ever running Java Updater in the first place.

After installing Java, unload the job temporarily, and remove the symlinks so that it's not loaded again after a restart. You'd run something like this with elevated privileges:

```bash
/bin/launchctl unload /Library/LaunchAgents/com.oracle.java.Java-Updater.plist
/bin/launchctl unload /Library/LaunchDaemons/com.oracle.java.Java-Helper.plist
/bin/rm -f /Library/LaunchAgents/com.oracle.java.Java-Updater.plist
/bin/rm -f /Library/LaunchDaemons/com.oracle.java.Java-Helper.plist
```

You might think, like I [did](https://groups.google.com/d/msg/macenterprise/Vjoe-qo1ttA/Gkk4NyS2nfYJ), that you can just `launchctl unload -w` the job to set it as permanently disabled. It [turns out](https://groups.google.com/d/msg/macenterprise/Vjoe-qo1ttA/5dzpAUemVkEJ) you **absolutely should not do** this, due to an oversight in the Java 7 installer's postinstall script. Having these jobs disabled will cause the script, and thus the entire install, to fail.

**Advantages:** We don't need to mess with any configuration of the updater mechanism itself.

**Disadvantages:** We're still changing the "expected state" of the Java installation, and the fact that disabling the job permanently (ie. `launchctl unload -w`) causes future installations to fail doesn't inspire confidence that any of Oracle's future pre/postinstall scripts will be robust enough or perform even basic sanity checks. We also need to make sure that we unload the job and remove symlinks after every installation. Unloading is actually optional, since that the next update check will usually be a week from the time of installation, and a reboot will cause the launchd jobs to never be loaded again.


### Current status

I don't think either option is generally viable, especially if you're in environment with a diverse set of client configurations (laptops, admin users, remote workers and sites, etc.) and need to make as few assumptions as possible about how client machines are used and maintained. If, on the other hand, you maintain control over at least software installations and updates, you might decide one of these two workarounds could work despite its limitations, at least until a better solution is discovered or implemented.

After I complained in [##osx-server](http://webchat.freenode.net/?channels=#%23osx-server) on IRC, Michael Lynn [found](http://osx.michaellynn.org/freenode-osx-server/freenode-osx-server_2013-02-23.html) a channel through which to report bugs against the JRE, and Rich Trouton documented the steps and caveats in a [blog post](http://derflounder.wordpress.com/2013/02/23/filing-bugreports-with-oracle-for-mac-os-xs-java-7). If you support Java on your Macs and this is an issue for you, file a bug!
