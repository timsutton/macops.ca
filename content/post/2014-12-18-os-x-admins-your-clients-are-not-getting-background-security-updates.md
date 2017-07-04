---
date: 2014-12-18T16:50:48Z
slug: os-x-admins-your-clients-are-not-getting-background-security-updates
tags:
- Gatekeeper
- Software Update
- xprotect
title: 'OS X admins: your clients are not getting background security updates'

wordpress_id: 845
---

Have I got your attention? The more accurate (and longer) qualifier for this title should actually be: "admins who configure clients to not automatically check for software updates."

From recent discussions in [##osx-server](https://botbot.me/freenode/osx-server), some of us have determined that OS X's "system data files and security updates" will only install automatically _if a client is already configured to automatically check for updates_. Many sysadmins managing OS X clients tend to disable this setting so that they can control the distribution of these updates, but aren't aware that their clients are now no longer receiving Apple's background updates for at several of its built-in security mechanisms, including [XProtect](http://www.thesafemac.com/tag/xprotect/) and [Gatekeeper](http://support.apple.com/en-us/HT202491).

Rich Trouton beat me to this post [with his post yesterday](https://derflounder.wordpress.com/2014/12/17/forcing-xprotect-blacklist-updates-on-mavericks-and-yosemite/), but it prompted me to do a bit more digging into trying to reproduce an issue that comes up when attempting the most obvious workarounds for this issue, which I'll outline after giving some more context.

**Update:** Greg Neagle has come up with a simple but flexible workaround for the issue described below, which he's implemented in Reposado and documented [here](https://managingosx.wordpress.com/2015/01/30/gatekeeper-configuration-data-and-xprotectplistconfigdata-and-munki-and-reposado-oh-my/). If you use Reposado (and you really should), look into the new `--remove-config-data` option that can be applied selectively to SUS updates you're mirroring.

<!--more-->

There are a couple of reasons admins usually disable automatic checks for software updates. Historically one reason was that their users weren't administrators, and therefore couldn't install software updates themselves even if we wanted them to. Since OS X Mavericks, by default any user can install software updates via the Mac App Store interface or just using the `softwareupdate` command-line tool (although there are [supported ways to configure this setting](https://github.com/gregneagle/profiles/blob/897af827325c47403ad24fd7e2e4d844d730487c/mavericks_app_store.mobileconfig)). A more important reason is that admins often want to maintain some control over when certain updates are actually rolled out to their clients, and do limited testing of system updates. This can be done using [Reposado](https://github.com/wdas/reposado) or Apple's [Software Update service](https://help.apple.com/advancedserveradmin/mac/4.0/#/apdE691575F-EDA4-4903-B09C-A49858EA1AEA) included in OS X Server, both of which allow local mirroring of Apple's own Software Update catalogs for your managed clients (Reposado does a much better job of this).

Disabling automatic checks for updates also has the effect of preventing the system from prompting the user about the new updates. This is usually done in tandem with an implementation of a client management platform like [Munki](https://github.com/munki/munki), which is able to provide the user with an interface to install the system updates coming from your own server. We are replacing Apple's user-facing mechanisms for system updates with our own.

Disabling the automatic checks is typically done by running the `softwareupdate --schedule off` command as part of a setup script, or setting `AutomaticCheckEnabled` to false in `com.apple.SoftwareUpdate`. We end up with an App Store preference pane that looks like this, with nothing checked:

{{< imgcap
    img="/images/2014/12/appstore-yos-prefs-none.png"
	caption="Running <code>softwareupdate --schedule off</code> leaves the App Store preferences like this."
>}}

In recent versions of OS X, Apple began using its Software Update service (which also drives system software updates that show in the App Store or via the `softwareupdate` command-line tool) as a mechanism for installing "background and critical" updates that are installed silently in the background with no notifications to the user. Here are several families of updates have been seen so far using this mechanism (and there are more):
  
1. XProtect, for storing plugin version blacklisting and malicious code signature info
1. The [GateKeeper Opaque Whitelist](http://indiestack.com/2014/10/gatekeepers-opaque-whitelist/)
1. Incompatible Kernel Extension Configuration Data


We'll take the first two as examples: XProtect stores its data in `/System/Library/CoreServices/CoreTypes/XProtect*` files, and Gatekeeper Configuration Data in `/private/var/db/gkopaque.bundle`. Both of these sets of files include standard `Info.plist` files with nice, always-incrementing integer version strings.

Users will never see these updates in the App Store UI. These updates may be run when other updates take place, but they also run on their own schedule.

If you run Reposado or Software Update Service in OS X Server, you'll see these updates listed alongside standard user-facing updates. If you look at the actual `.dist` that go alongside these updates, you'll notice these updates include a `config-data` "type" attribute up at the top in the `options` element. (Printing out an update's distribution file is easy with Reposado: `repoutil --dist `).

You may be enabling these updates along with other updates, thinking that they will get installed. They might, but only if the clients pointing to your server have automatic checks enabled.

{{< imgcap
	img="/images/2014/12/appstore-yos-prefs-checks.png"
	caption="App Store preferences with no automatic downloads/installs, just checks"
>}}

See some of the undocumented `softwareupdate` Greg Neagle has [documented here](http://managingosx.wordpress.com/2013/04/30/undocumented-options/), namely the `--background` and `--background-critical` options. You might think, what if we just run these commands ourselves on a schedule? With these options, Software Update will schedule a scan (returning immediately) for installing _only_ the `config-data` updates, but it _will not actually install_ them if background checks are disabled.

I'd encourage you to test this for yourself: find a test client that has been been configured with background checks disabled for some time (these updates, particularly Gatekeeper, are frequently updated by Apple, often at least every couple of weeks). If you can't find one, you can manually adjust the `CFBundleShortVersionString` in `/private/var/db/gkopaque.bundle/Contents/Info.plist` to something lower than the current version, which is listed as the update version in the Software Update catalog (again with Reposado, visible with `repoutil --updates`). At the time of writing this post, the current version is `52`, released December 10, 2014.

Making sure first that you have automatic checks disabled:

`sudo softwareupdate --background-critical
softwareupdate[47096]: Triggering background check with normal scan (critical and config-data updates only) ...`

While running this you can run a `tail -f /var/log/install.log` and see the activity log:

```
Dec 17 09:49:15 host.my.org softwareupdated[494]: Received xpc_event: ManualBackgroundTrigger
Dec 17 09:49:15 host.my.org softwareupdated[494]: BackgroundActivity: Initiating com.apple.SoftwareUpdate.Activity activity
Dec 17 09:49:15 host.my.org softwareupdated[494]: BackgroundActivity: Starting Background Check Activity
Dec 17 09:49:15 host.my.org softwareupdated[494]: BackgroundActions: Automatic checking disabled
Dec 17 09:49:15 host.my.org softwareupdated[494]: BackgroundActivity: Finished Background Check Activity
```

That was pretty quick. Now go back and enable background checks (via the App Store Preference Pane, `softwareupdate --schedule on` or a `sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true`) and re-run the `sudo softwareupdate --background-critical` command. The trigger will occur and `softwareupdate` will return immediately, but you should now see some more interesting activity in your `install.log`. Here's a snippet of mine run today:

```
Dec 17 10:00:25 host.my.org softwareupdated[494]: Available Products Changed
Dec 17 10:00:25 host.my.org softwareupdated[494]: Scan (f=1, d=1) found 5 updates: 031-14032, 031-14180, 031-14221, 031-14263, 041-9395 (plus 119 predicate-only)
Dec 17 10:00:25 host.my.org softwareupdated[494]: BackgroundActions: 0 user-visible product(s):
Dec 17 10:00:25 host.my.org softwareupdated[494]: BackgroundActions: 5 enabled config-data product(s): 031-14032, 031-14180, 031-14221, 031-14263, 041-9395 (want active updates only)
Dec 17 10:00:25 host.my.org softwareupdated[494]: BackgroundActions: 0 firmware product(s):
```

There were actually five different configuration data updates found in this run: Apple Displays metadata, Chinese Wordlist, Incompatible Kexts, XProtect and Gatekeeper Opaque Bundle. You'll see later in the install log that they all get installed.

So given that we can ensure these are installed by enabling automatic _checks_, what's to stop us just disabling automatic _installations_ on clients, and leaving the checks enabled? Earlier I mentioned that enabling automatic checks has the effect of prompting the user to install them when recommended updates are found, and since these updates are now part of the App Store application, this prompt may also include available updates for App Store apps (which you may not want if you are already distributing using an institutional Apple ID or have disabled updates of App Store apps by regular users).

Since I wanted to ensure I could reproduce this reliably on Mavericks and Yosemite, I ended up recording a short video (see below). This demonstrates the App Store prompt that seems to occur if automatic checks are enabled, a manual run of `softwareupdate --background-critical` is done when there are other available updates.

{{< youtube 3XdrFY2wKWg >}}

A couple of additional points. If you try to reproduce this, you may have inconsistent results because of the notification system having its own schedule of when it decides to notify the user (relative to when it did last, what feedback the user gave, etc.). The second point is that I've had _some_ success on Yosemite in simply disabling the automatic check _immediately_ after scheduling the check. In other words:

```bash
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
sudo softwareupdate --background-critical
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
```

In my limited testing on Mavericks, this triggered the prompt anyway, and in my limited testing on Yosemite, it didn't. But either way, this would be a fragile mechanism to rely on. I would not be confident that I have covered enough scenarios in testing to implement some kind of scheduled script that would run these commands in an attempt to automate these updates on clients.

An another approach to getting these updates out to clients would be via scripting or something like [AutoPkg recipes](https://github.com/autopkg) to fetch the packages from Apple's Software Update servers. This would allow an admin to deploy the packages in any way he/she sees fit. The problem with this approach, however, is that one would need to keep a close eye on exactly what conditions these updates install. This is determined by the pkg `.dist` files, and specifically a pile of difficult-to-read JavaScript functions doing mostly boolean logic in order to isolate updates to clients meeting specific conditions. The Gatekeeper and XProtect examples I've described in this article follow somewhat predictable patterns, but it's common for updates like these to be split across multiple OSes, merged together, split again, get reposted, etc. It would be a lot of work for someone to continue to audit these distribution files to ensure that the right updates are going to the right clients. A misplaced code signature patch going into your clients' `/System/Library` could have serious implications.

The fact that it's common practice for admins to disable software update checks, and that this disables all installation of config-data updates, seems to clash with Apple's desire to keep their OS updated quickly and transparently with configuration data that helps the systems function more reliably and securely. I consider this issue to be a security bug. My bug report on this issue is [#18939764](rdar://18939764), which has been classified by Apple as an enhancement request.
