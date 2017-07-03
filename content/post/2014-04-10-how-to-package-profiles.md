---
comments: true
date: 2014-04-10T20:51:38Z
slug: how-to-package-profiles
tags:
- packaging
- Profiles
- Python
title: How to Package Profiles

wordpress_id: 653
---

<!-- [![Pkg_256.png](images/2014/04/Pkg_256.png)](images/2014/04/Pkg_256.png) -->

Part of a managed Mac's configuration is often one or more Profiles, either Configuration Profiles, or an Enrollment Profile for an MDM server like [Apple's Profile Manager](http://www.apple.com/ca/support/osxserver/profilemanager/) or [Cisco Meraki Systems Manager](https://meraki.cisco.com/products/systems-manager).

There are multiple ways to install these. You can have users double-click and install these .mobileconfig files themselves via a website or e-mail if they have administrative rights on their machines. You can have [DeployStudio](http://www.deploystudio.com/) install them as part of a workflow and not care how it's done, or have a management service like the [Casper Suite](http://www.jamfsoftware.com/products/casper-suite/) configure and manage them for clients (and again, not need to care how it's done).

But if we want the most portable way possible to install a profile on a Mac, it might be the simplest to fall back to the Mac's lingua franca of software configuration (for better or for worse): the Installer Package. A profile that can be installed via a package install can be installed with _any_ management software (even [Apple Remote Desktop](http://www.apple.com/ca/remotedesktop/), version 3 turning 8 years old tomorrow). And like a profile, it can simply be opened and installed like any other piece of software by a technician or user.

This question comes up often enough for people using [Munki](https://code.google.com/p/munki/), or other management systems that don't have some kind of purpose-built mechanism for dealing with profiles. Generally these are the steps:

  1. Have the package install the profile somewhere like any other file.
  1. Run the command `/usr/bin/profiles` (as root) in a postinstall script to install this profile.
  1. There's no step three.

Actually, there is if you'd like to also include a mechanism to remove the profile: You'd want to write some short script that would remove the profile, as well as configure the system so that it can know that this profile is no longer installed. Since we're using an installer package, we have the benefit of being able to check for a receipt of the package.

You also might like to install this profile on an non-booted volume (either a clean image built with something like [AutoDMG](https://github.com/MagerValp/AutoDMG), or a Mac system connected via Target Disk Mode). But since we don't have `profiles` available, we actually want to install it to a special place that OS X looks for at boot time for any profiles to install: `/private/var/db/ConfigurationProfiles/Setup`, as well as clear a special `.profileSetupDone` file that may exist if this volume has been already booted. This has been documented [already elsewhere](http://www.afp548.com/2012/06/01/automating-enrollment-of-lion-into-profile-manager-on-os-x-server/). If you build images for deployment, you may have scenarios in which it's important for the profile to be installed on the system's first boot rather than later in its software management cycle.[1. An important distinction here is to set the package to use the full path starting with `/private/var` rather than simply `/var`, which is actually a symlink. It's been reported to have caused issues in some cases before, and it's simply not correct: install files to real paths rather than symlinks whenever possible.]

I got tired of fiddling with these details and making errors copying and pasting profile packaging/uninstall scripts from one profile to another, so I wrote a short Python utility to make this easier to automate. It's called "make-profile-pkg", and it [lives here on GitHub](https://github.com/timsutton/make-profile-pkg). There are more details on the how and why there on the GitHub page.

[Graham Gilbert](http://grahamgilbert.com) contributed a couple great things on this: He helped make it a generic pkg-building tool rather than a Munki-specific tool, and also added the logic in the postinstall script for it to do the right thing about the install location depending on whether the package is used on a booted or non-booted volume. This allows a single package built with this utility to be installable on both booted and non-booted volumes. In addition to building the package with a few configurable options, it will also generate an uninstall script that can be used in conjunction with your software management platform of choice.

[As of December 12, 2014](https://github.com/timsutton/make-profile-pkg/commit/f8828736c5eb545c6461cb00a5b0d6e03093847a), the tool also generates an `installcheck_script` that will be used by Munki to check whether the profile is actually installed, since in some cases it may be possible for a user to remove the profile after the package has installed it. The script used here is from Graham's MacTech 2014 session on using Munki for client configuration.
