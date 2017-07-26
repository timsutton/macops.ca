---
title: "What macOS Version Did I Just Download?"
date: 2017-07-26T00:00:00Z
slug: "what-macos-version"
tags:
  - macos-deployment
---

When downloading the latest macOS Installer from the App Store, there's no obvious way to confirm the exact macOS version in the installer from looking at the install assistant application itself. It's been my experience that while the version of the _installer app itself_ always increments, its version number is in no way related to the version of the macOS install image contained within (even though sometimes Apple seems to follow a certain pattern for a few point releases..)

{{< imgcap
  img="/images/2017/07/sierra_12.3_getinfo.png"
  title="Sierra 10.12.3 installer"
  caption="'Get Info' dialog for the Sierra 10.12.3 installer. The 2nd component in the version info above happened to match the minor OS version in later Sierra installers, but not this one."
>}}

It's often happened that CDNs take up to a few hours to offer the newer macOS installer, even when the [App Store HTML](macappstores://itunes.apple.com/app/id1127487414) tends to update to the latest version immediately after Apple releases the updates to their [Software Update catalogs](https://swscan.apple.com/content/catalogs/others/index-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog). There's no obvious way to tell, just from looking at the installer app, what OS version you've actually downloaded if you're getting it right at the time of release (or ever, for that matter).

The CDN propogation delays for the installers seem to have improved recently, but generally one still always wants to confirm that they've downloaded a newly-released version. I also often find myself looking at an installer app on some system, somewhere, and I just want to know what version it is.

New in macOS Sierra and up (at the time of writing, High Sierra beta 4), there's an `InstallInfo.plist` file located alongside the `InstallESD.dmg` image in the `SharedSupport` directory, which seems to contain this info. For example, to look at the version for the Sierra installer:

```shell
$ plutil -p '/Applications/Install macOS Sierra.app/Contents/SharedSupport/InstallInfo.plist'
{
  "Additional Wrapped Installers" => [
  ]
  "System Image Info" => {
    "id" => "com.apple.dmg.InstallESD"
    "version" => "10.12.6"
    "sha1" => ""
    "URL" => "InstallESD.dmg"
  }
  "Additional Installers" => [
  ]
  "OS Installer" => "OSInstall.mpkg"
}
```

With the version available within the `System Image Info` dictionary key, we can access this very easily using a plist parser of our choosing. Using the built-in `PlistBuddy` tool is one way, despite PlistBuddy's awkward syntax:

```shell
$ /usr/libexec/PlistBuddy -c 'Print :System\ Image\ Info:version' '/Applications/Install macOS Sierra.app/Contents/SharedSupport/InstallInfo.plist'
10.12.6
```

Previously I used to navigate to `Contents/SharedSupport/InstallESD.dmg`, double-click to mount it, then mount `BaseSystem.dmg` to get at the `System/Library/CoreServices/SystemVersion.plist` file within _that_. At this point, I may need to be in a terminal window, because `BaseSystem.dmg` has the hidden file flag, and the Finder may not be showing hidden files unless we've already set `defaults write com.apple.finder -bool AppleShowAllFiles true`, so this is simply easier.

We can quickly glean this without needing to mount anything or access any hidden files. It's possible using just the Finder and Quick Look, even.

Note that in this output we're missing the exact OS build version – `16G29` in this case for 10.12.6. This can be either parsed from the `OSInstall.mpkg` package Distribution file (as [createOSXInstallPkg has been doing](https://github.com/munki/createOSXinstallPkg/blob/ec13f6433f67d80fc55b91608259cd5e326ed3fc/createOSXinstallPkg#L273-L290) for many releases now), or as mentioned above, mounting `BaseSystem.dmg` and reading the `SystemVersion.plist` within. You'll want to always verify build numbers if you're ever working with [hardware-specific macOS installers](https://derflounder.wordpress.com/2012/06/26/downloading-lion-os-installers-for-your-specific-mac-model/).
