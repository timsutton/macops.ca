---
date: 2015-10-07T15:24:37Z
slug: the-office-for-mac-2016-volume-license-installer-two-months-later
tags:
- Office 2016
- packaging
title: The Office for Mac 2016 Volume License Installer, Two Months Later
---

<!-- [![pkg_office](images/2015/10/pkg_office-300x298.png)](images/2015/10/pkg_office.png) -->

It is now over two months since Microsoft has made the Office for Mac 2016 Volume License installer available for customers in the VLSC (Volume Licensing Service Center) portal. I have [previously documented](http://macops.ca/whats-wrong-with-the-office-2016-volume-license-installer/) a couple major issues with the installer that impact those who deploy Office 2016 using automated means (meaning anything that doesn't involve a user manually running the GUI installer).

In this post I'll summarize two of the major issues and talk a bit about a conference session that was presented just this past week at MacSysAdmin 2015 by Duncan McCracken.


### Running at the loginwindow: fixed, sort of

The Office for Mac team has made some [progress](http://macops.ca/whats-wrong-with-the-office-2016-volume-license-installer/#comment-17855) with one of the major issues with this installer, which was its inability to run the license activation process while at the loginwindow. The latest release in the VL portal at this time of writing is 15.13.4, and it fixes the issue where the license activation (run by Microsoft Setup Assistant) assumed it could connect to a GUI session, which at the loginwindow it cannot.

Unfortunately, they have not yet met what I'd consider the minimum requirement for a deployable installer: that it should be possible to deploy it with Apple Remote Desktop (ARD). While ARD has a (deserved) reputation of being unreliable and is not suitable for ongoing management of Macs at a larger-than-small scale, it's still an easy-to-set-up tool that you can point a software vendor to as a way to test how well their installers stand up to a typical mass deployment scenario.

The reason the Office VL installer fails at the loginwindow with ARD was already explained in the afore-linked post: ARD seems to set a `USER` environment value of `nobody`, and when their licensing tool runs it is run using `sudo -u $USER`, which seems to fail when the command is run as `nobody`. I don't see any reason why `sudo -u $USER` should be used at all in this case.


### Confusing security prompt for the auto-update daemon: still there

The other major issue with the installer is that when it detects `COMMAND_LINE_INSTALL`, it skips the process of registering the Microsoft AU Daemon application (using an undocumented `-trusted` option) using `lsregister`, because this should be done as the user launching the app. The end result is that installing this package without other additional steps will result in a confusing "you are running this for the first time" prompt shown to users, triggered by the auto-update daemon, which is triggered automatically on the first launch of any Office 2016 application.

Working around this issue requires some fancy footwork: setting preferences for `com.microsoft.autoupdate2` to prevent it from launching automatically, or using an installer choice changes XML to selectively disable Microsoft Auto Update (MAU) from installing at all. The latter won't help much if Office 2011 has already been installed, because Office 2011 includes the same Auto Update application, and the 2016 applications will attempt to register themselves with it on first launch. Another option, which requires no modification to the installation configuration, is to instead create a custom script to run the same `lsregister` command, and run this script by every user at login time, deployed using a tool such as [outset](https://github.com/chilcote/outset).

Admins have also gone the route of simply deploying the standalone "update" packages instead of the base application, as these don't include the MAU components at all. This is also all documented thoroughly in my [earlier post](http://macops.ca/whats-wrong-with-the-office-2016-volume-license-installer/).

These advanced workarounds - repackaging, recombining, reconfiguring and "augmenting" with additional LaunchAgents - are all excellent examples of things that should never be required by an IT administrator for mainstream software. These techniques are typically only needed for niche applications made by software vendors whose release engineers have little interest in understanding the conventions and tools available for the OS platform. Adobe is obviously the one glaring exception here.


### The audit by Duncan McCracken at MacSysAdmin 2015

Last week the MacSysAdmin 2015 conference took place in Göteborg, Sweden. Duncan McCracken, whose company [Mondada](http://www.mondada.com.au/) offers a paid Mac packaging service, spent the latter half of his presentation deconstructing the Office 2016 installer.

A video recording of Duncan's presentation, as well as some his resources used in the demo, can be found at the [MacSysAdmin 2015 documentation](http://docs.macsysadmin.se/2015/2015doc.html) page (or [here](http://docs.macsysadmin.se/2015/video/Day3Session4.mp4) for a direct link of the video).

Because Mondada specializes in packaging as a service, Duncan is an expert at doing packages _properly_, and is experienced with fixing the mistakes made by commercial vendors who don't properly implement the tools made available by the Installer framework and packaging tools on OS X. Somewhat of a perfectionist, Duncan is used to completely disassembling and re-assembling a flawed package (or one that uses a custom packaging engine - see his [2010 MacSysAdmin Installer Packages session](http://docs.macsysadmin.se/2010/2010doc.html) for an example) to make it as "correct" as possible, and using the appropriate mechanisms available in the Installer framework to perform whatever custom logic may be necessary.

The Office 2016 package deconstruction begins roughly halfway into the video. As someone who's all-too-familiar with problematic installer packages (and Office 2016's in particular), I found the session extremely entertaining. The parts of Duncan's demos that didn't go so well were supposedly caused by a misconfigured (or broken?) shell binary in his OS X VM he was using in the demonstration, and that the process he went through to re-assemble the installer package should otherwise have resulted in a successful installation.

Given that Mac IT admins are still in this awkward phase where OS X El Capitan is now shipping on all new Mac hardware, Outlook 2011 effectively cannot run on El Capitan, and organizations are feeling pressure to deploy Office 2016 as soon as possible, it's unfortunate that the Office 2016 installer still requires so much "fixing." I'm willing to go out on a limb and say that Office is the single most commonly deployed commercial software in organizations.

That Duncan dedicated nearly half of his session to this installer package is a testament to how far IT admins need to go simply to deploy software in a manner that provides a trouble-free experience for users. Software vendors do not have a _clue_ that we do this - so don't think that they are "out to get you" - but when software becomes this hard to deliver to users, it's time to push back and give real-world examples of the contexts in which we install software and details of the workarounds we implement. You may well better understand the implications of `sudo -u $USER` in postinstall scripts than the release engineers do, so educate them!

There's even [contact info in a comment](http://macops.ca/whats-wrong-with-the-office-2016-volume-license-installer/#comment-17855) from my previous post. If you don't have an expensive enough agreement with Microsoft (we don't), it can otherwise be challenging to get a fruitful contact with the engineering team, so this is an opportunity to provide direct feedback.
