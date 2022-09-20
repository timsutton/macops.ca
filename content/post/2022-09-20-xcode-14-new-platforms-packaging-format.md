---
title: Xcode 14's New Platforms Packaging Format
date: 2022-09-20T08:21:03-04:00
slug: xcode-14-new-platforms-packaging-format
tags:
  - Xcode
  - simulators
  - developer-tools
---

Nearly *ten years ago*, I [published a post]({{< relref "/post/2012-11-19-xcode-deployment-the-dvtdownloadableindex-and-ios-simulators.md" >}}) about how to download and deploy the iOS simulator runtimes independently of the Xcode app bundle. This is certainly the oldest post on the blog that I could say was still useful and accurate!

Prior to Xcode 14, one could navigate to the 'Components' section of the app preferences and download previous simulators. Under the hood, a "dvtdownloadableindex" plist file would be downloaded from Apple, containing metadata and templated URLs to download installer packages containing the full simulator runtime operating system packages, and then installed directly to the host's filesystem inside `/Library/Developer/CoreSimulator/Profiles/Runtimes`. This resulted in a lengthy installation time due to the huge number of files (watchOS 9 simulator *alone* is over 180K files), and Xcode's interface provided no method (that I could find, at least) to remove these large runtime packages, leaving you to figure out where they'd been installed and remove them yourself.

Xcode 14 makes some big changes to this underlying infrastructure:

* Instead of installer packages, it uses a new disk-image-based distribution and storage mechanism for new optional simulators.
* A new family of `simctl` commands to manage the above simulators: `xcrun simctl runtime <verb>`
* Xcode no longer bundles watchOS and tvOS runtimes with the app bundle, only a current iOS runtime. This makes the Xcode .xip download several GBs smaller and faster to install (~10GB down to ~7GB).
* The Xcode Preferences UI renames 'Components' to 'Platforms'.
* `xcodebuild` also has a new option to tell it to download _all_ additional platforms: `xcodebuild -downloadAllPlatforms`:
  ```
  ➜ xcodebuild -downloadAllPlatforms
  Downloading tvOS: 17%
  ```
* The simulator downloads are now protected behind a ADC (Apple Developer Center) login, but Xcode obtains one transparently by using a public endpoint to obtain a ADC authentication cookie, which can *also* be used to download other assets from ADC such as Xcode itself!


Apple now has their own documentation on some of this, which you can find [here](https://developer.apple.com/documentation/xcode/installing-additional-simulator-runtimes).


## diskImage simulator type

From now on, simulator runtimes will be downloaded as a single DMG. A new daemon executable located at `/Library/Developer/PrivateFrameworks/CoreSimulator.framework/Resources/bin/simdiskimaged` is responsible for managing a simple database at `/Library/Developer/CoreSimulator/Images`, and then for keeping them mounted at special hidden mountpoints at  `/Library/Developer/CoreSimulator/Volumes`.

At the time of writing, Xcode 14.1 is in beta, including the iOS 16.1 SDK and simulator runtime. And as one might expect, we can ask Xcode 14.1 to download the iOS older 16.0 runtime using the **+** button in the bottom left corner to access previously-released simulators:

{{< imgcap
  caption="New view displaying all previously-released iOS simulators – 16.0 is the first iOS Xcode downloadable to use the new DMG instructure."
  img="/images/2022/09/ios16-previously-released-fs8.png"
>}}


## Mountpoint management

The new `simdiskimaged` process will manage keeping these runtimes' filesystems mounted at the special mountpoints as they are needed by the system. My experience has been that this process will start up when Xcode or `xcodebuild` is first used, and then these volumes will stay mounted indefinitely.

As an experiment, I unmounted my watchOS runtimes using Disk Utility, and expected `simdiskimaged` to simply re-mount it when it would determine it was needed; `xcrun simctl runtime list` had still shown it in a "Ready" state. However, Xcode seemed to disagree: it no longer showed watchOS as an available simulator and its Platforms view indicated it was not installed. So, it stands to reason that one should leave the mounted simulator runtimes alone when they happen to turn up in Disk Utility or via the `diskutil` CLI tool.


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

Not much changes for iOS 16.0, besides using the new `diskImage` content type and the `authentication` key (more on that further down in this poast). We also seem to have finally dropped the need to put [Unix epoch dates](https://www.epochconverter.com/) in the package version (I presume these may have been to appease the Installer framework):

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

With previous sim runtimes, one would use Apple's sim runtime installer package and need to resort to gymnastics to expand the contents in the expected location (because Xcode's installation uses a private Installer framework API), and then wait several minutes for all those tiny files to write to the filesystem. This time adds up if you're repeatedly setting up build hosts that need multiple different runtime versions for tests.

The new system is now faster, while still supporting automation using Apple's CLI tools. Now, simply stage the DMG onto your target system using your method of choice, and pass it to the new `xcrun simctl runtime` family of commands:

```
➜ xcrun simctl runtime add 'iOS 16.0 simruntime.dmg'
```

There is an additional verification step that will take place after the this `runtime add` command has returned, and  `runtime list -v` will output something like this during the process:

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

..you'll the system policy security evaluation process busy for a short while:

{{< imgcap
  img="/images/2022/09/ios16-verify-cpu-fs8.png"
>}}

..and then a familiar 'verifying' UI in the Finder:

{{< imgcap
  img="/images/2022/09/ios16-verify-finder-fs8.png"
>}}


## Authentication

Let's look into the change related to the new `authentication` key in the above dvtdownloadable metadata. This is also new for the new DMG-based format. Previous simulator runtime download URLs were always possible to download anonymously. But, you may have noticed that Xcode never requested any ADC login in order to install these new runtimes. So, how did that work?

Xcode simply passes the runtime download path to a special endpoint at this host: `developerservices2.apple.com`, and receives a response containing the `Set-Cookie` header containing a `ADCDownloadAuth` cookie, which it then uses to fetch the original URL contained in that dvtdownloadable item. For example, to download the tvOS 16.1 beta simulator, it first makes the request to:

```
# original URL from dvtdownloadableindex:
# https://download.developer.apple.com/Developer_Tools/tvOS_16.1_beta_Simulator_Runtime/tvOS_16.1_beta_Simulator_Runtime.dmg

https://developerservices2.apple.com/services/download?path=/Developer_Tools/tvOS_16.1_beta_Simulator_Runtime/tvOS_16.1_beta_Simulator_Runtime.dmg
```

..and then the cookie it returns can be used to fetch the original URL:


```
➜ curl -vLO \
  --cookie "ADCDownloadAuth=<cookie value>" \
  "https://download.developer.apple.com/Developer_Tools/tvOS_16.1_beta_Simulator_Runtime/tvOS_16.1_beta_Simulator_Runtime.dmg"
```


A nice side effect of this change, is that this ADC auth cookie can now be obtained and used to download Xcode itself, meaning that for the first time ever, it is now possible to download Xcode .xip files from ADC *without needing to authenticate*! This is handy for the use-case of setting up automation to fetch and archive Xcode installers on internal servers, which was often trickier to do because of Apple's general 2FA requirement on Apple IDs.


## Takeaways

Overall, the new DMG-based distribution is a win for its shrinking down Xcode's default install size, speeding up the installation of new runtimes, and improving the ergonomics for managing them. We didn't discuss the security improvement in the tools here either, but it stands to reason that up-front signature verification and Gatekeeper assessment of the runtimes is also a very welcome addition.
