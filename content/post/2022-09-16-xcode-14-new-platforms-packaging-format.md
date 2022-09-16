---
title: Xcode 14's New Platforms Packaging Format
date: 2022-09-16T08:21:03-04:00
slug: xcode-14-new-platforms-packaging-format
tags:
  - Xcode
  - simulators
  - developer-tools
---

Nearly ten years ago, I published a [post]({{< relref "/post/2012-11-19-xcode-deployment-the-dvtdownloadableindex-and-ios-simulators.md" >}}) about how to download and deploy the iOS simulator runtimes independently of the Xcode app bundle. This is certainly the oldest post on the blog that I could say was still useful and accurate!

Prior to Xcode 14, one could navigate to the 'Components' section of the app preferences and download previous simulators. Under the hood, a "dvtdownloadableindex" plist file would be downloaded from Apple's server, containing metadata and templated URLs to download installer packages containing the full simulator runtime operating system packages, and then installed directly to the host's filesystem inside `/Library/Developer/CoreSimulator/Profiles/Runtimes`. This resulted in a lengthy installation time due to the huge number of files (watchOS 9 simulator *alone* is over 180K files), and Xcode's interface provided no method to remove these large runtime packages, leaving you to figure out where they'd been installed and remove them yourself.

Xcode 14 makes some changes:

* Instead of installer packages, it uses a new disk-image-based distribution and storage mechanism for new optional simulators.
* New family of `simctl` commands to manage the above simulators.
* Xcode no longer bundles watchOS and tvOS runtimes with the app bundle, only a current iOS runtime. This makes the Xcode .xip download several GBs smaller and faster to install (~10GB down to ~7GB).
* The Xcode Preferences UI renames 'Components' to 'Platforms'.
* `xcodebuild` also has a new option to tell it to download _all_ additional platforms: `xcodebuild -downloadAllPlatforms`:
  ```
  ➜ xcodebuild -downloadAllPlatforms
  Downloading tvOS: 17%
  ```

## diskImage simulator type

From now on, simulator runtimes will be downloaded as a single DMG. A new daemon executable located at `/Library/Developer/PrivateFrameworks/CoreSimulator.framework/Resources/bin/simdiskimaged` is responsible for managing a simple database at `/Library/Developer/CoreSimulator/Images`, and then for keeping them mounted at special hidden mountpoints at  `/Library/Developer/CoreSimulator/Volumes`.

At the time of writing, Xcode 14.1 is in beta, including the iOS 16.1 SDK and sim runtime. And as one might expect, we can ask Xcode 14.1 to download the iOS older 16.0 runtime using the **+** button to access previously-released simulators:

{{< imgcap
  caption="New view displaying all previously-released iOS simulators – 16.0 is the first iOS downloadable to use the new DMG instructure."
  img="/images/2022/09/ios16-previously-released-fs8.png"
>}}

## Metadata simplicity

There's a couple new things to like about the newer metadata file that Xcode uses to present and download these runtimes.

Previously, the DVT Downloadables index URL included a GUID from an Xcode tooling version that would change across different versions, and so one would generally need to have an active Xcode installation and a Mac just to know the index URL. The new index URL is just a stable URL, which makes it easier to automatically scrape using some internal monitoring script or tool:

https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex

The contents of the index was also not super friendly to human parsing when one just wanted to download the runtime disk images, with many values being template placeholders like `https://devimages-cdn.apple.com/downloads/xcode/simulators/$(DOWNLOADABLE_IDENTIFIER)-$(DOWNLOADABLE_VERSION).dmg`, which required some mental effort to put back together and were a couple nested layers deep. The new format is more condensed and simply contains the full URLs verbatim for the older package-based runtimes, and includes the new dmg-based runtimes in the same file.

In this plist file, you can parse the `contentType` key and look for either `diskImage` (the new format) or `package` (the old format).

Here's iOS 15.4, for an example of how the older package-based format looks:

```xml
<dict>
    <key>category</key>
    <string>simulator</string>
    <key>contentType</key>
    <string>package</string>
    <key>dictionaryVersion</key>
    <integer>2</integer>
    <key>fileSize</key>
    <integer>5425406116</integer>
    <key>identifier</key>
    <string>com.apple.pkg.iPhoneSimulatorSDK15_4</string>
    <key>name</key>
    <string>iOS 15.4 Simulator</string>
    <key>platform</key>
    <string>com.apple.platform.iphoneos</string>
    <key>simulatorVersion</key>
    <dict>
        <key>buildUpdate</key>
        <string>19E240</string>
        <key>version</key>
        <string>15.4</string>
    </dict>
    <key>source</key>
    <string>https://devimages-cdn.apple.com/downloads/xcode/simulators/com.apple.pkg.iPhoneSimulatorSDK15_4-15.4.1.1650505652.dmg</string>
    <key>version</key>
    <string>15.4.1.1650505652</string>
</dict>
```

Not much changes for iOS 16.0, besides using the new `diskImage` content type, and we seem to have finally dropped the need to put Unix epoch times in the package version (I preseume these may have been to appease the Installer framework):

```xml
<dict>
    <key>authentication</key>
    <string>virtual</string>
    <key>category</key>
    <string>simulator</string>
    <key>contentType</key>
    <string>diskImage</string>
    <key>dictionaryVersion</key>
    <integer>2</integer>
    <key>fileSize</key>
    <integer>6280680540</integer>
    <key>identifier</key>
    <string>com.apple.dmg.iPhoneSimulatorSDK16_0</string>
    <key>name</key>
    <string>iOS 16 Simulator Runtime</string>
    <key>platform</key>
    <string>com.apple.platform.iphoneos</string>
    <key>simulatorVersion</key>
    <dict>
        <key>buildUpdate</key>
        <string>20A360</string>
        <key>version</key>
        <string>16.0</string>
    </dict>
    <key>source</key>
    <string>https://download.developer.apple.com/Developer_Tools/iOS_16_Simulator_Runtime/iOS_16_Simulator_Runtime.dmg</string>
    <key>version</key>
    <string>16.0.0.0</string>
</dict>
```



## Installing independent runtimes using simctl

With previous sim runtimes, one would use Apple's sim runtime installer package and need to resort to gymnastics to expand the contents in the expected location (because Xcode's installation uses a private Installer framework API), and _then_: wait multiple minutes for all those tiny files to write to the filesystem. This time adds up if you're setting up a build host that needs multiple different runtime versions for tests.

The new system is now faster, while still supporting automation using Apple's CLI tools. Now, simply stage the DMG onto your target system using your method of choice, and pass it to the new `xcrun simctl runtime` family of commands:

<TODO: command example>


There is an additional verification step to this installation, where Xcode's UI will display a text of "Registering..":

`xcrun simctl runtime list -v` will output something like this during the process:

```
-- unknown --
<unknown platform> - 9F503C5C-136A-4B2A-8FDC-5AADAB79DEAD
    State: Verifying
    Image Kind: Disk Image
    Signature State: Unknown
    Deletable: YES
    Mount Policy: Automatic
    Size: 5.8G
```

..you'll system policy security processes busy for a short while:

<TODO: image with syspolicyd>

..and then a familiar 'verifying' UI:

<TODO: image with Finder verifying iOS 16.0>



## 





One issue with the previous system was that the Xcode UI didn't provide a way to delete older simulator runtimes once they'd been installed. One could remove them by deleting them directly off the filesystem, but 


New docs from Apple:
https://developer.apple.com/documentation/xcode/installing-additional-simulator-runtimes

