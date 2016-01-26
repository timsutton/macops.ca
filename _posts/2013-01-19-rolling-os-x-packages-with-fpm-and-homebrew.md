---

comments: true
date: 2013-01-19 20:15:54+00:00
layout: post
slug: rolling-os-x-packages-with-fpm-and-homebrew
title: Rolling OS X packages with FPM and Homebrew
wordpress_id: 299
tags:
- fpm
- homebrew
- packaging
---

Two cool open-source package managers, FPM and Homebrew, recently got some new OS X Installer Package capabilities.

## fpm -t osxpkg


Jordan Sissel's [FPM](https://github.com/jordansissel/fpm) packaging tool was designed for systems administrators to very easily roll packages for RedHat, Debian and other platforms and abstract away the obscure details of the package formats themselves.

FPM is written in Ruby, and I decided (somehow) it could be a fun learning exercise to look at implementing support in it for building OS X packages. FPM version 0.4.27 was released a few days ago, available as a `gem install`, and now supports OS X package input and output, at least on OS X platforms with pkgbuild installed (built-in on OS X 10.8 and 10.7, for 10.6 requires an installation of Xcode 3.2.6 or later).

OS X packages are almost always used in a very different context than rpms and debs (and you are  hopefully never going to need to convert an rpm to an OS X package), but building them with FPM still allows one to benefit from some cool features FPM provides all with a single command invocation:

  * automatically build packages from RubyGems, Python packages and others. `fpm -s python -t osxpkg psutil` builds a pkg of the latest psutil Python module that will install to the build system's default `site-packages` folder. You can specify an alternate version to fetch with `--version`.
  * pre/postinstall scripts can be ERB-templated with any properties of the package, ie. the version.
  * a package's source can be a simple tarball, and you define the installation prefix.

In addition to what we get with FPM for free, the `osxpkg` package type in FPM also supports a few extras, the more noteworthy ones being: custom [`restart-action`](http://managingosx.wordpress.com/2012/07/05/stupid-tricks-with-pkgbuild/) and [`dont-obsolete`]({% post_url 2012-12-18-flat-packages-persisting-obsolescence %}) values as simple command options rather than requiring manual PackageInfo templates. More options could easily be added as FPM already has built-in methods for templating package metadata files.


## brew pkg

I was recently learning how to update a [Homebrew](https://github.com/mxcl/homebrew/tree/master/Library/Formula/dfu-programmer.rb) package (ie. 'formula') so that I could compile an up-to-date version of [dfu-programmer](http://dfu-programmer.sourceforge.net) on my Mac. I was reminded of several times at work when recent versions of packages I wanted to install were available in Homebrew, but didn't want to just install Homebrew on a server, as it is targeted more towards developer systems and assumes ownership of /usr/local. I did like the idea that specific 'formulae' are maintained voluntarily by people who probably know more than I about configuring/running a particular software on OS X, and that these are shareable and forkable if I wanted to improve one myself.

Homebrew provides a nice way to provide added functionality via custom scripts, and so was born [brew-pkg](https://github.com/timsutton/brew-pkg), a command to build an OS X installer package from an installed formula, with a couple bonuses:

  * put service-related launchd plists in /Library/LaunchDaemons rather than a user folder
  * optionally include a package's dependencies in the built package
