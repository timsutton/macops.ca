---
title: New Adventures in Automating OS X Installs with startosinstall
tags:
- OS X
---

OS X El Capitan's installer includes a nifty new command-line tool called `startosinstall`, which can be used to automate installations and upgrades of OS X El Capitan via the command line. Since you may be already familiar with the [createOSXInstallPkg](https://github.com/munki/createOSXinstallPkg
) tool that can also help automate OS X installations, you might be wondering why you should care.

I'll go into some technical detail about what this tool does and how, but first let's go back a few years to provide more (and more) context.


### Lion, the birthplace of InstallESD

In environments where Macs are more centrally managed, deploying OS upgrades could be a pain point and involve either a lot of manual work or setting up NetBoot environments that can perform automated OS upgrades.

With the [release](https://www.apple.com/ca/pr/library/2011/07/20Mac-OS-X-Lion-Available-Today-From-the-Mac-App-Store.html) of Mac OS X Lion In 2011, Apple ceased distributing their OS X installers on optical media and switched to the Mac App Store as the primary method of distributing the OS. Without the ability to simply boot the installer from a DVD, this new installer would need some additional tooling to be able to stage its installer setup environment from the currently-running OS, boot into it and complete the installation in an automated fashion.

### createOSXInstallPkg

As soon as OS X Lion was released, [Greg Neagle](https://managingosx.wordpress.com/) quickly reverse-engineered the process of what the OS X Install Assistant was doing to set up the rest of the automated installation, and came up with a clever deployment tool that eventually matured into [createOSXInstallPkg](https://github.com/munki/createOSXInstallPkg). This command-line tool takes the installer as input, and outputs a standard Apple installer package that can be used in nearly any context to "deploy the OS." In the docs, Greg outlines in [greater detail](https://github.com/munki/createosxinstallpkg#how-it-works) what exactly the tool does that makes this possible.

This has been a _fantastic_ tool for the Mac admin community: it enables one to, with a single package installer that can be built automatically in minutes, both install an OS onto a bare system and upgrade an existing system, and do it in a variety of contexts:

* software management systems like [Munki](https://github.com/munki/munki) or [Casper](http://www.jamfsoftware.com/products/casper-suite/) / [d3](https://github.com/PixarAnimationStudios/depot3), for automated or self-service installs
* NetBoot-based deployment environments: [DeployStudio](http://www.deploystudio.com/), [Imagr](https://github.com/grahamgilbert/imagr/)
* any other means you can install packages: Remote Desktop, Target Disk Mode, or manual package installation

As a bonus, this installer can be customized with additional packages to install, which are added to the OS installer package "collection" using functionality supported by Apple's own [System Image Utility](https://support.apple.com/en-ca/HT202770). Since these additional packages are installed after the OS is installed, additional bootstrapping can take place when the machine first boots, and provide just enough configuration to have the machine check in to a system for ongoing management.

Since 2011, Greg Neagle has likely all but stopped building images and over time has convinced many others to as well. createOSXInstallPkg has enabled many interesting OS upgrade scenarios for managed environments, even if machines are initially deployed using traditional imaging methods.

### System Integrity Protection and bless

So why am I still talking about createOSXInstallPkg? What about this new `startosinstall` command? Still more context is needed:

OS X 10.11 El Capitan introduced [System Integrity Protection (SIP)](https://derflounder.wordpress.com/2015/10/01/system-integrity-protection-adding-another-layer-to-apples-security-model/), which impacts systems management tools in interesting ways. During WWDC it was made clear, thanks to [thorough](https://forums.developer.apple.com/message/7098) [scouting](https://forums.developer.apple.com/message/45637) [reports](https://forums.developer.apple.com/message/9062) from attendees Rich Trouton and Erik Gomez posted to the Apple developer forums, that the `bless` tool would be one system component that would be subject to SIP's increased security restrictions. Rich Trouton also has [many informative posts](https://derflounder.wordpress.com/category/system-integrity-protection/) on issues and infrastructure related to SIP.

[`bless`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man8/bless.8.html) has long been the system command used to configure boot targets for the system. It's what createOSXInstallPkg uses to tell the OS that when it next boots, to use an alternate booter file and to mount a DMG as the root volume instead of the default OS volume, and with some specific parameters. This all mirrors Apple's Install Assistant app.

Prior to OS X 10.11, `bless` could also be used to remotely instruct a Mac to boot from a NetBoot server; in OS X 10.11, these servers must first be [whitelisted](https://support.apple.com/en-ca/HT205054), and this can only be done from a non-SIP-constrained environment like a NetBoot image or the Recovery Partition. So, there's a chicken-and-egg scenario if you're in the unfortunate position of relying on `bless --netboot` due to cross-subnet BOOTP restrictions imposed by your network (admins).

For those with dual-boot environments, `bless` could also be used to programmatically configure the Mac to boot from a Windows partition, and this is simply not possible if SIP is enabled. Tim Perfitt at Two Canoes has a [great writeup](http://blog.twocanoes.com/post/130271331763/how-el-capitan-boot-camp-is-affected-by-apples) on how SIP affects Boot Camp. If this concerns you, here are [two](http://www.openradar.me/22436692) [radars](http://www.openradar.me/22618232) you can [dupe](http://quickradar.com).

### Install OS X El Capitan DP{1,7}.app

During the 10.11 developer preview period, SIP was initially announced but it wasn't clear when these then-forthcoming restrictions would actually ship in a DP build and in exactly what form. It didn't help the testing of OS X installer issues that over two months went by without Apple releasing an updated full OS installer (from early June to mid-late August 2015). Eventually, a later DP build of El Capitan (somewhere around build 7 or 8) seemed to implement this `bless` restriction that prevented createOSXInstallPkg from working as designed - the `bless` command used by the tool would fail in the default scenario where SIP is enabled.

As of today, the latest version of OS X is 10.11.4, and a 10.11.4 package built by createOSXInstallPkg works as desired when SIP is still enabled. Of course, today there's no reason to use an El Capitan OS install package _on top of_ an El Capitan system, and older OS versions can upgrade to it using a createOSXInstallPkg-built pkg. However, with SIP's supposed restrictions on the use of `bless`, all signs point towards this method being a no-go for upgrading El Capitan systems to Apple's _next_ major OS version shipping later this year.

### startosinstall

`startosinstall` lives in the `Contents/Resources` directory in the "Install OS X.app" bundle along with other familiar [CLI](https://support.apple.com/en-ca/HT201372) [tools](https://managingosx.wordpress.com/2012/08/15/creating-recovery-partitions/). Here's its usage statement:

```bash
$ '/Applications/Install OS X El Capitan.app/Contents/Resources/startosinstall'
Usage: startosinstall --applicationpath <install os x.app path> --volume <target volume path>

Arguments
--volume, a path to the target volume.
--applicationpath, a path to copy of the OS installer application to start the install with.
--license, prints the user license agreement only.
--usage, prints this message.

Example: startosinstall --volume /Volumes/Untitled --applicationpath "/Applications/Install OS X.app"
```

Note that a destination volume can be specified. This invocation will also display end user license information in the console and require you interactively accept it. This can be automated by **1)** passing the requested '`A`' character to the process via stdin (i.e. `echo 'A' | startosinstall ...`), or **2)** running the tool using the undocumented `--nointeraction` flag.

What happens next? The install is staged just like when you use the old Install Assistant (or createOSXInstallPkg!). If you're already familiar with the installation staging steps, the items logged to `/var/log/install.log` may look familiar (I've omitted some disk plist output here to save space):

```
16:16:52 osinstallersetupd[1920]: Verifying InstallMacOSX.pkg/InstallESD.dmg
16:17:06 osinstallersetupd[1920]: Operation queue succeeded
16:17:06 osishelperd[1921]: IASGetCurrentInstallPhaseList: no install phase array set
16:17:06 osishelperd[1921]: IASGetCurrentInstallPhase: no install phase set
16:17:06 osinstallersetupd[1920]: Opening /OS X Install Data/InstallESD.dmg
16:17:06 osinstallersetupd[1920]: mountDiskImageWithPath: /OS X Install Data/InstallESD.dmg
16:17:08 osinstallersetupd[1920]: Mounting disk image complete, results dict = {
    ...
	}
16:17:08 osinstallersetupd[1920]: Mount point /Volumes/OS X Install ESD
16:17:08 osinstallersetupd[1920]: Extracting boot files from /Volumes/OS X Install ESD/BaseSystem.dmg
16:17:08 osinstallersetupd[1920]: mountDiskImageWithPath: /Volumes/OS X Install ESD/BaseSystem.dmg
16:17:09 osinstallersetupd[1920]: Mounting disk image complete, results dict = {
    ...
	}
16:17:09 osinstallersetupd[1920]: Mount point /Volumes/OS X Base System
16:17:09 osinstallersetupd[1920]: Extracting Boot Bits from Inner DMG:
16:17:09 osinstallersetupd[1920]: Copied prelinkedkernel
16:17:09 osinstallersetupd[1920]: Copied Boot.efi
16:17:09 osinstallersetupd[1920]: Copied PlatformSupport.plist
16:17:09 osinstallersetupd[1920]: Ejecting disk images
16:17:09 osinstallersetupd[1920]: Generating the com.apple.Boot.plist file
16:17:09 osinstallersetupd[1920]: com.apple.Boot.plist: {
	    "Kernel Cache" = "/OS X Install Data/prelinkedkernel";
	    "Kernel Flags" = "container-dmg=file:///OS%20X%20Install%20Data/InstallESD.dmg root-dmg=file:///BaseSystem.dmg";
	}
16:17:09 osinstallersetupd[1920]: Done generating the com.apple.Boot.plist file
16:17:09 osinstallersetupd[1920]: Blessing / -- /OS X Install Data
16:17:09 osishelperd[1921]: ***************************** Setting Startup Disk ***************************
16:17:09 osishelperd[1921]: ******           Path: /
16:17:09 osishelperd[1921]: ******     Boot Plist: /OS X Install Data/com.apple.Boot.plist
16:17:09 osishelperd[1921]: /usr/sbin/bless -setBoot -folder /OS X Install Data -bootefi /OS X Install Daptions config="\OS X Install Data\com.apple.Boot" -label OS X Installer
16:17:09 osishelperd[1921]: GetModel: model = VMware; major rev = 7; minor rev = 1
16:17:09 osishelperd[1921]: Machine appears to be AR capable
16:17:09 osishelperd[1921]: Stash commit failed: 0xe00002bc (if stash was staged for an autologin user, this is expected)
16:17:09 osinstallersetupd[1920]: No principal user cookie will be written, commit was unsuccessful
16:17:09 osishelperd[1921]: Boot chime muted
```

There are some differences, however, between how you can run this tool and doing installs via a createOSXInstallPkg-built package.

### Where to run startosinstall

In my testing, I can't seem to run `startosinstall` from any environment besides the regular user GUI session using Terminal.app. A DeployStudio NetBoot environment and Recovery Partition environment both seem to not have the system components or configuration to be unable to actually start the installation staging process. The process also does not seem to start if invoked via SSH or Remote Desktop - I'll see a few preliminary progress items in `/var/log/install.log` but no actual start of the installation staging process.

I really hope that I'm just making a silly error in some of these cases, but I wonder if the security constraints around this tool is also limiting the contexts in which it can be successfully used.

### Immediate restart

When the install is staged, the tool attempts a graceful restart of the machine _immediately_. Conversely, if one were installing a package built with createOSXInstallPkg, the staging takes place but a restart can be done at a time of the admin's choosing, and the installation will take place on the next boot (although there is a time window beyond which the install will be considered invalid). This at least allows enough time for any finalizing steps to be performed, if the installation is taking place during some managed and reported installation process such as Munki or DeployStudio.

This automated restart by `startosinstall` is actually attempted using an [Apple event](https://developer.apple.com/library/mac/qa/qa1134/_index.html), which isn't a "hard" restart, giving the user the opportunity to save any unsaved documents, which can potentially halt the reboot. Here's what it looks like in an OS X VM where I'm actually running the `startosinstall` command:

{% include image.html
    caption="Graceful restart prompted by startosinstall"
    img="images/2016/04/startosinstall_reboot.png"
%}


For more details, you'll want to [spelunk](http://www.hopperapp.com/) the code that `startosinstall` actually interfaces with: `OSInstallerSetup` and `OSInstallerSetupInternal` frameworks, and the `osishelperd` and `osinstallersetupd` binaries, all in the Frameworks directory within the `Install OS X El Capitan.app` bundle. The latter is what actually contains most of the implementations of the actions that are performed. It's possible to get a glimpse of other interesting OS installer mechanisms if you're interested in that sort of thing.

At some point this system may fall back to a forced reboot: there _is_ code in `osishelperd` to execute `/sbin/shutdown -h now`, but I'm not sure this is ever invoked.

### Blessed by Apple

So why can `startosinstall` perform these `bless` commands, but we (mostly) cannot? Tools used by `startosinstall` are signed by Apple and possess entitlements that give it super abilities. Several of the binaries in the "Install OS X" app contain one or two of the entitlements shown below:

```bash
➜  ~ codesign -d --entitlements :- "/Applications/Install OS X El Capitan.app/Contents/Frameworks/OSInstallerSetup.framework/Resources/osishelperd"

Executable=/Applications/Install OS X El Capitan.app/Contents/Frameworks/OSInstallerSetup.framework/Versions/A/Resources/osishelperd
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.private.securityd.stash</key>
	<true/>
	<key>com.apple.rootless.install</key>
	<true/>
</dict>
</plist>
```

`com.apple.private.securityd.stash` seems to be used for the helper utility to stash FileVault credentials to be used for successive reboots. `com.apple.rootless.install` may well be what enables the use of `bless` to select the alternate boot volume and custom boot options.

### Closing thoughts

Generally, the fact that this utility exists is a step forward - it's an official tool provided by Apple that is clearly made to provide functionality that Apple would otherwise be restricting, restrictions that would impede the helpful automation that createOSXInstallPkg has enabled in many organizations small and large. This indicates that Apple is aware that there's a need for such a utility.

Several features that make createOSXInstallPkg great are:

* It works for upgrading OSes from 10.6.8 and up. `startosinstall` seems to require 10.10.
* The pkg installer makes the solution very portable. Any OS can run the installer onto any disk and it will have its installation files staged. That disk can then be booted on any machine and the OS will install. There is no assumption that the machine executing the installer is also the machine _that will perform the installation_, as is the case with `startosinstall`.
* The context in which the package is installed does not matter, as long as it has root privileges. It can be executed by a management tool, an interactive CLI over SSH using `installer`, Remote Desktop or just run manually like any other installer package.
* It is portable enough that it will work in a NetBoot image that includes Python: this includes DeployStudio and [Imagr-compatible NBIs](https://github.com/grahamgilbert/imagr/wiki/Updating-a-NetInstall) generated by [AutoNBI](https://bitbucket.org/bruienne/autonbi). There are no external tools required.
* Additional custom packages can also be added to seamlessly install any needed site-specific configuration on the machine immediately after the OS install, while still in the installer environment, using features provided already by Apple's installation framework. `startosinstall` and the `OSInstallerSetup` frameworks contain code to manipulate these package manifests but don't currently expose any of that to end users.

In its current state, I'm not sure `startosinstall` can satisfy any of these features I've listed above. But going forward, `startosinstall` this may be the _only way_ to automate installations of OS X on "live" systems, so now would be a good time to begin looking at this tool and seeing whether it meets your needs. If not, [file radars](http://bugreport.apple.com)! [Here's](https://developer.apple.com/bug-reporting/using-bug-reporter/) [how](https://derflounder.wordpress.com/2015/08/26/using-quickradar-to-file-bug-reports-with-apple/).
