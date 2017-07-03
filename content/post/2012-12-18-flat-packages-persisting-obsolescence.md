---
comments: true
date: 2012-12-18T00:22:20Z
slug: flat-packages-persisting-obsolescence
tags:
- packaging
- pkgbuild
title: 'Flat packages: persisting obsolescence'

wordpress_id: 241
---

<!-- [![pkg_256](images/2012/12/pkg_256.png)](http://macops.ca/flat-packages-persisting-obsolescence/pkg_256/) -->

Packaging is somewhat of a black art on OS X. The Flat Package format has been in existence since 10.5, but only recently are more 3rd-party packaging tools like [JAMF Composer](http://www.jamfsoftware.com/products/composer) starting to move to this format by default. PackageMaker's days as a hidden download in the Apple Developer Center Auxiliary Downloads package are [numbered](https://developer.apple.com/library/mac/#documentation/developertools/conceptual/PackageMakerUserGuide/RevisionHistory.html#//apple_ref/doc/uid/TP40005371-CH999-SW1). In this post I'll look at one aspect of the package system that's perhaps less widely known, the "ownership" of a file to a package, and how this affects behaviour that can be tweaked when building flat packages, using [pkgbuild](https://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man1/pkgbuild.1.html) as the reference package-building tool.

<!--more-->

By default, when an OS X package is installed, if it is an upgrade of a previous version (in other words, there is a package with the same _package identifier_ of a lower version number already installed), any files in its payload that were present in the previous version and not in the new version will be removed from the filesystem. This is because these files are associated with that version of a package in the package (ie. "receipts") database. When a new version of the package is installed, the Installer framework helpfully removes these files that are no longer part of the package's payload. In other words, if you install file `/usr/local/bin/my_script` in version 1, and instead only `/usr/local/bin/my_new_script` in version 2, `my_script` will be deleted if it was present when version 2 was installed, assuming that this package identifier is still known to the package database. (It wouldn't be if, for example, `pkgutil --forget my.package.identifier` was ever run manually or by an installer script).

We can use the built-in pkgutil tool to query the package database for metadata about packages (BOMs, identifiers, versions, etc.). To examine what package installed pkgbuild, for example, on this OS X 10.8.2 system:

```
➜  ~  pkgutil --file-info /usr/bin/pkgbuild

volume: /
path: /usr/bin/pkgbuild

pkgid: com.apple.pkg.BSD
pkg-version: 10.8.0.1.1.1306847324
install-time: 1351028588
uid: 0
gid: 0
mode: 755
```

`com.apple.pkg.BSD` is part of a standard OS X install.

One curious PackageInfo element [documented by Stéphane Sudre](http://s.sudre.free.fr/Stuff/Ivanhoe/FLAT.html) is the `dont-obsolete` element. As its name might suggest, "obsoleting" seems to be responsible for removing these files that are no longer present in upgraded package versions.

A real-world example: We recently had an internal support package included in our thin deployment image, one of whose payload items contained a template configuration file that was modified later as part of our DeployStudio workflow. I updated this support package with newer versions of unrelated components to be imported into [Munki](https://github.com/munki/munki) to push out to clients automatically, wanted to _not_ overwrite this file when Munki would automatically install the package, and at the same time not remove the old one. The `dont-obsolete` element turns out to be one solution to solve this problem within the logic of the package payload itself, without requiring workarounds in postinstall scripts that could potentially cause issues and greater complexity in the long term.

We can use the undocumented (but documented [here](http://managingosx.wordpress.com/2012/07/05/stupid-tricks-with-pkgbuild) by Greg Neagle) `--info` option for pkgbuild to supply the `dont-obsolete` element to be included in the final built `PackageInfo` file, using a template `PackageInfo` that looks like this:

```xml
<pkg-info>
    <dont-obsolete>
        <file path="/usr/local/bin/my_script"/>
    </dont-obsolete>
</pkg-info>
```

And to build the package:

```
pkgbuild --identifier my.package.identifier \
         --version 2.0 \
         --root /my/payload/root \
         --info /my/template/pkginfo-file \
         my_support_package-2.0.pkg
```

Assuming the package we're upgrading uses the same identifier and is a lower version number, this should do what we want, which is to persist the file at `/usr/local/bin/my_script` after the installation, even if it's not included in the 2.0 version of our package.

Instead of using the `--info` option, we could also build the package without it, then later use pkgutil with the `--expand` option, edit the PackageInfo file manually and finally `--flatten` it as I documented in this [earlier post on iOS Simulators]({{< relref "post/2012-11-19-xcode-deployment-the-dvtdownloadableindex-and-ios-simulators.md" >}}). This is of course much more work, but is easily automated.

Two asides:

pkgbuild also includes a useful `--prior [pkg-path]` option, which will automatically derive the identifier, version and install-location parameters from a package located at `pkg-path`. According to the pkgbuild manpage, however, this will convert the version number to an integer and increment it, which may not be what you want.

Also, there are some exceptions to when files are actually "obsoleted". For example, removing old files will not necessarily occur if the `PackageInfo` file has `bundle-version` elements defined, which would happen if one is packaging, for example, an application bundle. Using pkgbuild with the `--root` option will perform some analysis on the contents to extract bundle versions and place these in the `PackageInfo` file. Look into the `--analyze` and `--component-plist` plist options in the pkgbuild [manpage](https://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man1/pkgbuild.1.html) to customize these further. Managing bundle metadata with the pkgbuild and productbuild tools is quite a bit more advanced, so the example in this post is mainly useful for application/site-specific data in simple files.
