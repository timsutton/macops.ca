---
comments: false
date: 2013-02-11T17:13:58Z
slug: new-utility-xprotect-packager
tags:
- munki
- packaging
- vendor metadata
- xprotect
title: 'New utility: XProtect Packager'

wordpress_id: 368
---

Roughly a week after the first widespread panic with the XProtect mechanism disabling Java on OS X, the same thing happened with the Flash plugin, with Apple issuing a definition update blocking all old versions about 3 hours after the latest Flash was available. (At least this time a newer version _was_ available.)

It's clear that a management strategy could be very useful in environments where users aren't admins on their computers and can't install updates themselves. One such strategy is to simply disable the updater, but the definitions should still be pushed to clients as you roll out new plugin versions, to enforce minimum security requirements as well as be able to protect against known malware.

There was some talk on Twitter, IRC and [multiple](http://managingosx.wordpress.com/2013/02/01/more-thoughts-on-xprotect-updater) [posts](http://managingosx.wordpress.com/2013/02/04/still-more-on-the-xprotect-updater) on Greg Neagle's blog. I dug around the `XprotectUpdater` binary and posted some [ideas](http://macops.ca/monitoring-apples-xprotect-meta-feed-for-changes/) on how one could monitor this feed for changes.

I later realized that there are also multiple definition files: one for each major version of OS X, starting with Snow Leopard, when XProtect was first implemented. This means there will soon be four separate defintions to keep track of (at least until Apple stops providing security updates for Snow Leopard).

I wrote a basic utility to automate packaging up these changes as the definition file ('clientConfiguration.plist') is updated from Apple. Because what `XprotectUpdater` does to synthesize the two Xprotect definition files on the client is very simple, this tool can do the same thing, but for all available client versions. Meaning, you can run the command on a single machine (and on a schedule, if you wish) and automatically build new packages for all OS X client versions you support.

It's called XProtect Packager, available here:

[https://github.com/timsutton/XProtectPackager](https://github.com/timsutton/XProtectPackager)

It's also able to automatically push these updated packages to a Munki repository.

On the subject of Munki, there are a few different "auto-packager" tools that have been made available by different people. Because I wanted this tool to be self-contained and finished as quickly as possible, the mechanisms for building the package and importing into Munki are quite basic, and the tool's functionality would probably be better served by integrating into a tool like Per Olofsson's [AutoPkg](http://code.google.com/p/macautopkg) or [another](http://neographophobic.github.com/autoMunkiImporter) [recipe-based](https://github.com/jamesez/automunki) checking/building/importing tool for Munki integration. If one tool starts to see some more widespread adoption and community contribution, it would be great to integrate XProtect Packager's functionality into it.
