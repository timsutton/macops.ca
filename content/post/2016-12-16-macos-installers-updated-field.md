---
date: 2016-12-16T00:00:00Z
title: macOS Installers on the Mac App Store Now Show Date Updated
slug: macos-installers-update-field
---

Since 2011, it's been possible to obtain the OS installer from the Mac App Store, and one that's been updated to the latest point version of macOS / OS X. For example, after OS X El Capitan was released on September 30, 2015, it was possible over the subsequent months to download an installer that was updated for versions 10.11.1, 10.11.2, and so on.

Whenever a new point version is officially released, Apple generally updates the Mac App Store version within a few hours, and many admins who are anxious to inspect it, or build new and test new images or installers, begin downloading and checking the build number to see if they've got the new version. Sometimes the updated HTML has been posted, but CDNs have not propogated the actual installers. Sometimes the App Store takes longer (a day or two) to post a new build.

However, what's happened several times (for Lion, Mountain Lion, and especially lately with Sierra's updates) is that Apple silently bumps the installer build number for the same point update version. This has happened with 10.12.1, and just yesterday (December 15, 2016) with 10.12.2. The updated builds for 10.12.1 were `16B2657` moving to `16B2659`, and 10.12.2 went from `16C67` to `16C68`.

These may seem like small differences and they may well not contain changes that are worth the effort to re-download and re-build installers, Netboot images or the like. However in some cases they are important because they may "unify" support across all Mac hardware following a new model release, or in some cases they may contain an important security change or a fix in the installer itself.

Vigilant admins [notice](https://github.com/MagerValp/AutoDMGUpdateProfiles/pull/51) pretty quickly when these builds update, in big part thanks to [AutoDMG's "update profiles" system](https://github.com/MagerValp/AutoDMG/wiki/Maintaining-Update-Profiles). Presumably 10.12.2 was updated in the past 12-24 hours, and when I visited the page for Sierra in the App Store Mac app, I noticed that there's now an "Updated" field showing yesterday's date.

{{< imgcap
  img="/images/2016/12/macos-sierra-updated.png"
  caption="New 'Updated' field shows the date that the build went from 16C67 to 16C68."
>}}

All other Mac apps have always had this, but previously, the only date shown for an "Install OS X" app was the date of the original OS release, which doesn't help one determine whether the installer they may have is the latest available.

It would be even nicer if there were a way to quickly see the actual build. For example, by programatically downloading the "preflight" [Installer distribution file](https://developer.apple.com/library/content/documentation/DeveloperTools/Reference/DistributionDefinitionRef/Chapters/Distribution_XML_Ref.html) that the App Store caches and parses prior to actually attempting to download and "install" an item. But, just having this visual indicator of when the installer was "updated," if this continues, is a welcome change and an improvement over just showing the updated OS version.
