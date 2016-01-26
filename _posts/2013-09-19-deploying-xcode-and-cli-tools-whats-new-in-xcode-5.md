---

comments: true
date: 2013-09-19 19:17:22+00:00
layout: post
slug: deploying-xcode-and-cli-tools-whats-new-in-xcode-5
title: 'Deploying Xcode and CLI tools: what''s new in Xcode 5'
wordpress_id: 586
tags:
- vendor metadata
- Xcode
---

<!-- [![ApplicationLoader_128.png](images/2013/09/ApplicationLoader_128.png)](images/2013/09/ApplicationLoader_128.png)
 -->

Xcode 5 was released to the public on September 18 along with iOS 7. If you deploy Xcode and the command-line tools, a few things have changed since 4.x. There've been a couple other posts on this blog in the past about the steps required to successfully deploy [Xcode](http://macops.ca/xcode-deployment-the-dvtdownloadableindex-and-ios-simulators/) and/or [CLI tools](http://macops.ca/managing-xcode-cli-tools/).

In this post we'll look at what's new with Xcode 5.

<!-- more -->

### Review

The dvtdownloadable index (Apple's metadata plist-based feed for Xcode additional downloads, used by the "Downloads" area of Xcode's Preferences) remains at its same location:

[`https://devimages.apple.com.edgekey.net/downloads/xcode/simulators/index-3905972D-B609-49CE-8D06-51ADC78E07BC.dvtdownloadableindex`](https://devimages.apple.com.edgekey.net/downloads/xcode/simulators/index-3905972D-B609-49CE-8D06-51ADC78E07BC.dvtdownloadableindex).

You can monitor this URL for changes to find out when new components are available, as well as determine under what conditions they'll appear, how they are considered installed, etc.

The app still includes two device development-related packages that absolutely must be installed in order for Xcode to function. They still have the same meaningless package version numbers, so there's no easy way to know which version is present on a system besides manual installation of the packages included with a specific Xcode version. Automating the installation of these packages after copying Xcode.app to /Applications still seems the most sensible option here.



### Accepting the license


I don't recall ever needing to do this before, but this needs to be done and with root privileges:

`/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -license accept`

If this isn't done before first launching Xcode, it will prompt for admin rights to persist this change on the system (after displaying the EULA).

### CLI tools

It's a little-known fact that for the past couple of years, Xcode's CLI downloads don't actually require ADC authentication and are accessible via public URLs. **Update:** This seems to be still the case. Michael Kuron replied to this post below, with the info that as of a few hours after this was originally posted, that the CLI tools still don't require ADC access, which is good news.

Related, Xcode 5 contains a new Accounts management system that enables certain tasks that would otherwise be done via the ADC portal to be authorized and done within Xcode itself.

We can likely expect the state of getting CLI tools to change as well with Mavericks. See the "Developer Tools Install-On-Demand" feature listed at bottom of Apple's Mavericks [preview page](https://developer.apple.com/osx/whats-new).

### Some docsets also require ADC access

I'm pretty sure no docsets for public docs ever required ADC authentication, but now the 10.8 docsets do. It is still possible to install these without admin rights because there is a special authorization right that exists specifically for this: `com.apple.docset.install`.

To get a list of docsets and their actual download URLs in the same format at the other DVT downloads, check out the feed at this URL:

[`https://developer.apple.com/library/downloads/docset-index.dvtdownloadableindex`](https://developer.apple.com/library/downloads/docset-index.dvtdownloadableindex)

These docsets ship as standard packages, however they are similar to those for iOS simulators in that they do not include a target location in the pkg metadata. If you'd want to deploy these packages to their correct location as would be when handled by Xcode, you'd need to repackage them as I've outlined in [this post]({% post_url 2012-11-19-xcode-deployment-the-dvtdownloadableindex-and-ios-simulators %}).

<!-- TODO: chck for other places that post_url could be used -->
