---
date: 2016-02-07T00:00:00Z
tags:
- Xcode
title: Developer Binaries on OS X, xcode-select and xcrun
---

`xcode-select` is a command-line utility on OS X that facilitates switching between different sets of command line developer tools provided by Apple. Its primary function is to be a "master switch" for the actual paths resolved when invoking the commands for tools like `make`, `xcodebuild`, `otool`, etc.

From the manpage:

> The tool xcode-select(1) is used to set a system default for the active developer directory, and may be overridden by the `DEVELOPER_DIR` environment variable.

The developer tool binaries actually ship with OS X as shim binaries, which use a system library to resolve a path to a "Developer" directory, where all the actual executables, libraries and support files are installed. Let's see what `/usr/bin/git` is actually linked to:

```bash
➜  ~  otool -L /usr/bin/git
/usr/bin/git:
	/usr/lib/libxcselect.dylib (compatibility version 1.0.0, current version 1.0.0)
	/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1226.10.1)
```

What's really going on when we call these shim binaries?

Behind the scenes, if I run `/usr/bin/git`, this shim binary loads functions in `libxcselect.dylib` that can locate the path to the real binary, depending on how the system has been configured. One part of this process is to check whether this path contains `usr/lib/libxcrun.dylib`, and the [`xcrun`](https://www.unix.com/man-page/osx/1/xcrun/) tool, in which case it will invoke `xcrun` to run the binary.

The `xcrun` binary seems to be present in developer directories included with Xcode but not the CLI tools, and it's also able to query information about SDKs and their included tools. `libxcrun.dylib` is a hard requirement for a developer dir to be validated, however. Try for yourself: temporarily rename `usr/lib/libxcrun.dylib` within a developer dir like `/Library/Developer/CommandLineTools` and then try to `xcode-select --switch` to it. `xcode-select` will error that it's an invalid directory.

(If all of this isn't yet enough indirection for you, `/usr/bin/xcrun` itself is a shim, and so `libxcselect.dylib` contains code to detect whether the executed `xcrun` is a shim. Look for the `__xcrun_shim` segment in the `__DATA` section output by the command: `pagestuff /usr/bin/xcrun -a`.)


### Developer directories

Xcode apps include a Developer directory at `Contents/Developer` within the app bundle, where among many other things, all the command line tools are installed.

Starting in OS X 10.9, Apple began making it very easy to get the [CLI tools installed on-demand]({{< relref "/post/2013-10-23-installing-command-line-tools-automatically-on-mavericks.md" >}}). Not every use case calls for a full Xcode installation, and the CLI tools are a tiny fraction of the install footprint of Xcode. The CLI tools from this package live in `/Library/Developer/CommandLineTools`.

The CLI tools are sufficient for providing some common developer tools, but they don't include the SDKs or `xcodebuild`needed to build Xcode projects. In some cases, native extensions in packages for other languages like Ruby and Python also require Xcode.

So, it's often the case that one might end up with both an Xcode and the CLI tools package installed, and at some point there may be [confusion](https://github.com/nodejs/node-gyp/issues/341) about when one is required over the other. In my experience Xcode always contains the full set of CLI tools. However, if a system at some point has either been switched to a different developer dir, an Xcode app was moved, or Xcode itself has been recently upgraded (silently, from the Mac App Store, and a [new license has yet to be accepted, for example]({{< relref "/post/2015-11-26-deploying-xcode-the-trick-with-accepting-license-agreements.md" >}})), one might reason that both Xcode _and_ CLI tools are required for some tasks, when this shouldn't be the case.

That being said, I'd like to know if there is a case where the CLI tools provided with Xcode apps are insufficient and the separate CLI tools package is required because it provides something not included with Xcode.


### How directories are auto-selected

Check the currently selected directory with `xcode-select` using the `-p/--print-path` option. Here's mine:

```bash
➜  ~  xcode-select -p
/Applications/Xcode-7.2.app/Contents/Developer
```

You can then use the `-s/--switch` option to change this path.

Chances are you've worked on a machine where you've never had to run `xcode-select -s` to explicitly select a directory, and other times you have. The `libxcselect` library linked to by `xcode-select` (the same linked to by the `git` shim binary we showed earlier) has a series of configuration checks it will perform to try and auto-discover a developer directory, and assuming it finds one, `xcode-select -p` will tell us what that is.

Below are what I've deduced its order of checks to be. Remember that this checking is the responsibility of `libxcselect`. `xcode-select` simply provides a way of manipulating some configuration on the system that `libxcselect` will make use of when one of these shim commands is run, or if `xcrun` is invoked directly by the user with specific options.

1. If the `DEVELOPER_DIR` environment variable is set when a command is run, any system default will be overridden.
1. If a symlink at `/var/db/xcode_select_link` is present and it points to a valid developer dir within an Xcode or the CLI tools, this will be used. This symlink will be created when running `xcode-select -s <path>` if `<path>` is either an alternate Xcode path or that of the CLI tools, and there is _already_ an `Xcode.app` in `/Applications`.
1. If neither of the above are set, and the path `/Applications/Xcode.app/Contents/Developer` is present, this is used.
1. If no Xcode path as above are set, but CLI tools are installed in `/Library/Developer/CommandLineTools`, these are selected.

A [disassembly](http://www.hopperapp.com) of `/usr/lib/libxcselect.dylib` also suggests that there is an additional check performed, similar to the symlink check, if a file is present at `/usr/share/xcode-select/xcode_dir_path`. This path is protected by [System Integrity Protection](https://en.wikipedia.org/wiki/System_Integrity_Protection), however, so it's likely only used internally for development.

As mentioned earlier, when a directory switch is attempted, `libxcselect` will perform a sanity check to at least ensure that the `usr/lib/libxcrun.dylib` library exists within the directory.
