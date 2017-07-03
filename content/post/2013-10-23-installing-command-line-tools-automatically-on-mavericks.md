---
comments: true
date: 2013-10-23T13:01:01Z
slug: installing-command-line-tools-automatically-on-mavericks
tags:
- Command Line tools
- PyObjC
- Python
- Software Update
- Xcode
title: Installing Command Line Tools automatically on Mavericks

wordpress_id: 486
---

In Mavericks, the Xcode Command Line Tools can be downloaded from the ADC downloads page like with previous versions. Now, though, they can be also be installed on-demand in a similar fashion to how Java has been installed since Lion, by simply invoking a command installed by them such as `otool`, or a new option in the `xcode-select` utility: `--install`.

{{< imgcap
    img="/images/2013/10/xcodeselect-install@2x.png"
>}}

In this post we'll look at how you can trigger and run this installation in an automated way, eliminating the need for any user interaction.

<!--more-->

We can guess from the dialog window that this mechanism might use Apple's Software Update servers as the source of the installer. You'd also already know this if you run your own Software Update service or Reposado (which is also included in JAMF Software's NetSUS appliance), and could have been syncing the Mavericks SUS catalog since June.

This task is a great opportunity to get familiar with how you can use an update's `.dist` file to identify what criteria makes an update "available" when the Software Update framework is invoked on a client.

Reposado makes this easy: get the list of updates with `repoutil --updates`, and note the item for the CLI tools:

`031-1006        Command Line Developer Tools for OS X Mavericks    5.0.1.0    2013-10-22 []`

Now print out an update's dist by passing its ID to the `--dist` option:

`./repoutil --dist 031-1006`

We get back a bunch of XML, much of which is JavaScript code that the client will run in order to evaluate whether this update applies to it. Here's a section that looks interesting (and is even commented more than usual):

```js
function isVisible() {
    // Must have a prior version of CLTools_Executables installed, or have the file marker that indicates and install-on-demand is in progress.
    var receipt = my.target.receiptForIdentifier('com.apple.pkg.CLTools_Executables');
    if (null == receipt) {
        // No receipt found for CLTools_Executables, check if the IOD application
        // is running. We do this by expecting the IOD application to create the
        // temporary file we check below for existence.
        if (system.files.fileExistsAtPath("/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress")) {
            return true;
        } else {
            return false;
        }
    }
```

The trigger mechanism is spelled out here. There are other checks within in this .dist's `script` tags that must be satisfied, for example the OS must be 10.9, and the user must not have already the receipt for this package present on the system. But here we can see the extra bit that the GUI helper application does for us: it touches a temporary file at `/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress` so that when functions in the Software Update framework are called, the helper application can find and install the appropriate update.


Similarly, Rich Trouton has also (of course) previously [documented](http://derflounder.wordpress.com/2013/06/24/installing-apples-updated-java-for-os-x-2013-004-and-java-for-mac-os-x-10-6-update-16-over-previous-versions/) the trigger necessary to do an automated install of the latest Java 6 update available in Software Update, which uses an environment variable instead of a trigger file.

Note also the `<tags>` tag:

```xml
<tags>
    <tag>DTCommandLineTools</tag>
    <tag>com.apple.dt.commandlinetools.10.9</tag>
</tags>
```

The tags are something that the Software Update framework or helper tools can parse to filter out candidate update packages. These are usually used by system tools and preferences other than `softwareupdate[/cci] itself, for example for finding Boot Camp ESD packages, printer drivers and speech assets.

Now that we've taken a side-tour of Software Update .dist files and how you can make use of them to identify how OS X software updates are parsed and selected, let's get back to why we're here: to install the CLI tools on Mavericks (and future OS X versions that will hopefully continue to use this mechanism). Now that we know the trigger file needed, the rest is straightforward.

A simple, though not exactly clean, way to do this is to scrape the output of the softwareupdate utility to extract the label for the update we want. I have a general-purpose script for installing Xcode CLI tools on 10.7 through 10.9 [here](https://github.com/timsutton/osx-vm-templates/blob/master/scripts/xcode-cli-tools.sh).

<!--TODO: Note that this continues to work with El Cap -->

It looks for the section of text we're interested in like this:

```
Software Update found the following new or updated software:
   * 031-1006-5.0.1.0
    Command Line Developer Tools for OS X Mavericks (5.0.1.0), 99103K [recommended]
```

By looking for the word "Developer" and then passing `softwareupdate` the label next to the asterisk in the line above.

This is less than ideal, because if either the wording of the update, or the command output formatting of `softwareupdate` were to change, this tool would break and we would need to fix it.

An better alternative might be to look at the contents of `/Library/Updates/ProductMetadata.plist` after running `softwareupdate -l`, and search  the tags that were already extracted for us in a nice structured format. We find an item like this:

```xml
<dict>
    <key>cachedProductKey</key>
    <string>031-1006</string>
    <key>tags</key>
    <array>
        <string>DTCommandLineTools</string>
        <string>com.apple.dt.commandlinetools.10.9</string>
    </array>
</dict>
```

Unfortunately, the "label" that `softwareupdate` can take to install a specific update still needs the longer version ("031-1006-5.0.1.0"), so we'd need to do even more work to do this using only structured data.

One way would be to look at the `com.apple.SoftwareUpdate` any-user defaults domain and the `RecommendedUpdates` key:

```
defaults read /Library/Preferences/com.apple.SoftwareUpdate RecommendedUpdates
(
        {
        "Display Name" = "Command Line Developer Tools for OS X Mavericks";
        "Display Version" = "5.0.1.0";
        Identifier = "031-1006";
        "Product Key" = "031-1006";
    },
        {
        "Display Name" = iTunes;
        "Display Version" = "11.1.2";
        Identifier = iTunesXPatch;
        "Product Key" = "zzzz091-9742";
    },
        {
        "Display Name" = "Java for OS X 2013-005";
        "Display Version" = "1.0";
        Identifier = JavaForOSX;
        "Product Key" = "091-7363";
    }
)
```

We could find our ID in the `Identifier` sub-key, then take the value o that item's `Display Version` key, then feed both of these to `softwareupdate` joined by a hyphen. This would eliminate the need to do any kind of parsing of the `softwareupdate` command output.

Because all this work would require sifting through plist contents, it's probably no surprise that I'd recommend Python to do this; besides having easy support for working with plists mapped to native data structures, on OS X it can also natively access the `com.apple.SoftwareUpdate` preferences domain using Objective-C (via the PyObjC framework). So, this is left up for either a rainy day and/or an exercise for the reader. In the meantime, the less-than-ideal <a href="https://github.com/timsutton/osx-vm-templates/blob/master/scripts/xcode-cli-tools.sh">shell script version</a> works.