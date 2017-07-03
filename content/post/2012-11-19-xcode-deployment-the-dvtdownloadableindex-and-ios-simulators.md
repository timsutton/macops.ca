---
comments: true
date: 2012-11-19T13:45:19Z
slug: xcode-deployment-the-dvtdownloadableindex-and-ios-simulators
tags:
- deployment
- flat packages
- iOS SDK
- pkgutil
- vendor metadata
- Xcode
title: 'Xcode deployment: The dvtdownloadableindex and iOS Simulators/SDKs'

wordpress_id: 96
---

<!-- ![](images/2012/11/xcode_IDEDownloadsIcon_64.png) -->

Around the time of the release of OS X Mountain Lion, Xcode moved to a single drag 'n drop .dmg model to simplify the user installation experience, and Apple was nice enough to make the Command Line tools a separate download. Unfortunately, this hasn't simplified the process of mass deployment, and we now have more moving pieces to keep track of than ever before. Anyone who's deployed Xcode recently may be familiar with its laundry list of post-installation tasks.

Some downloads, like the Command-Line Tools and earlier iOS Simulator/SDK versions, show up in a new "Components" download area located in Xcode's Preferences. We'll look at where this index comes from, how we can inspect it to get the iOS simulator .dmg download URLs, and one method of modifying the simulator installer packages so that they install to the correct location via any standard package distribution method like Munki or Casper. If you manage installing the Command-Line Tools as well, you'll find metadata here that will help with tracking version installs (anyone who's tried to manage deploying/updating them knows they _don't_ use Apple package versioning).

{{< imgcap
    caption="Xcode Preferences: Downloads"
    img="/images/2012/11/xcode-4.5.2-dvt@2x.png"
>}}


We'll also quickly review the other steps typically required to "finalize" the Xcode installation for most deployment scenarios. Big thanks to [Nate Walck](http://afp548.com/author/natewalck) for testing what I'd originally documented for the iOS Simulator installation and determining that I'd skipped an important step!

<!--more-->

Deploying Xcode via a software management mechanism such as Munki, Casper or ARD usually requires a few steps for a fully-functional install. These usually include:

  * copy the Xcode.app bundle from the .dmg to /Applications
  * copy out the MobileDevice.pkg (and MobileDeviceDevelopment.pkg as of Xcode 4.5) from Xcode.app/Contents/Resources/Packages and install them separately
  * assuming your users are not admins, adding an appropriate user group to the _developer group, and running `/usr/sbin/DevToolsSecurity -enable`, which handles modifying the security policies in `/etc/authorization`
  * optionally install the Command Line Tools for the appropriate OS version
  * optionally accept EULAs and configure the options for downloading extra components and documentation, via the defaults domain at `com.apple.dt.Xcode`


Installing these additional components has been already [documented](http://derflounder.wordpress.com/2012/07/26/building-a-grand-unified-xcode-4-4-installer-for-both-lion-and-mountain-lion) [in](http://code.google.com/p/munki/wiki/Xcode) [several](https://jamfnation.jamfsoftware.com/discussion.html?id=4034) [places](https://groups.google.com/group/macenterprise/browse_frm/thread/7058446425120177), but I hadn't yet seen anyone describe how they deployed versions of the iOS Simulator/SDK, which normally would be an optional component download.

Xcode seems to automatically include the most current version of the SDK in its .app bundle, so this is primarily useful if you want to be able to deploy older versions as well. But if you manage Xcode it's a good idea to become familiar with this index file anyway.

I recently discovered via the [Charles web proxy](http://www.charleswebproxy.com) tool what Xcode actually downloads from Apple to populate its list of additional components for download, which is also used to determine how they're installed. It turns out these indexes are also cached locally on the client, so no web traffic sniffing is even needed.

Once you've launched Xcode at least once as a user, head over to that user's Xcode cached downloads folder at `~/Library/Caches/com.apple.dt.Xcode/Downloads`.

```
-rw-r--r--@ 147M 1 Jul 11:52 Xcode.CLTools.10.7-1.3.1.dmg
-rw-r--r--@ 136M 11 Aug 22:24 Xcode.CLTools.10.7-4.4.1.3.2.dmg
-rw-r--r--@ 137M 12 Nov 21:14 Xcode.CLTools.10.7-4.5.7.dmg
-rw-r--r--@ 528M 17 Sep 00:10 Xcode.SDK.iPhoneSimulator.5.0-5.0.0.1.dmg
-rw-r--r--@ 400K 17 Sep 00:11 Xcode.SDK.iPhoneSimulator.5.0-5.0.1.1.dmg
-rw-r--r--   12K 20 Oct 17:27 eded78df8bfabaf6560841d10cf8e53766f74f28.dvtdownloadableindex
-rw-r--r--  8.3K  9 Jul 19:43 f7133e82a08bdb4ebf724f16beed2bbac2a265cf.dvtdownloadableindex
-rw-r--r--   11K 13 Nov 21:28 f9556a99100ac5200138e50480d2471b6bdc4adc.dvtdownloadableindex
```

In mine, I have some cached downloads (which Xcode helpfully renamed to saner filenames than it stores on its downloads site), and a few different index files. Each one is from a different version of Xcode. On this machine I've gone from version 4.3 to 4.4. to 4.5, and I believe these index filenames remain the same for patch versions. The only one getting updated now is the last one dated Nov 13, f9556a...dvtdownloadableindex.

These cached versions are binary plists, so either first convert them to the XML plist format or open them an editor like [TextWrangler](http://barebones.com) or [TextMate](https://github.com/textmate/textmate), which support transparent conversion of binary plists. If we open this up, we can see it serves a purpose similar to Apple's Software Update .sucatalog files, except all its logic and metadata is inline. One item to take note of is the `source` key at the bottom:

```xml
<key>source</key>
<string>https://devimages.apple.com.edgekey.net/downloads/xcode/simulators/index-3905972D-B609-49CE-8D06-51ADC78E07BC.dvtdownloadableindex</string>
```

The GUID in this URL seems to be unique to the Xcode major version, as is the SHA-1 that makes up the filename stored in the local cache. A couple useful header values from the web server for this URL:

```
ETag: "b16e24a220cced60c26a1d0693c669fa:1351889685"
Last-Modified: Fri, 02 Nov 2012 20:54:45 GMT
```

The ETag in this case is an md5 of the file and the time it was modified in the [Unix time format](http://en.wikipedia.org/wiki/Unix_time). Given this, you could monitor changes to either of these headers to know when there may be new changes in the index. (Of course, this index URL would likely change when there's a new major release of Xcode. At the time of writing the most recent version is 4.5.2, but inside the index there is at least one update restricted to only the preview release of Xcode 4.6).

The meat is in the downloadables array, so let's look at one dict entry from it:

```xml
<dict>
    <key>dependencies</key>
    <array/>
    <key>fileSize</key>
    <integer>553669951</integer>
    <key>identifier</key>
    <string>Xcode.SDK.iPhoneSimulator.5.0</string>
    <key>name</key>
    <string>iOS 5.0 Simulator</string>
    <key>source</key>
    <string>http://devimages.apple.com/downloads/xcode/simulators/ios_50_simulator-1.dmg</string>
    <key>userInfo</key>
    <dict>
        <key>ApplicationsBlockingInstallation</key>
        <array>
            <string>com.apple.iphonesimulator</string>
        </array>
        <key>IconType</key>
        <string>IDEDownloadablesTypeSimulator</string>
        <key>InstallPrefix</key>
        <string>$(DEVELOPER)</string>
        <key>InstalledIfAllPathsArePresent</key>
        <array>
            <string>$(DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk</string>
        </array>
        <key>RequiresADCAuthentication</key>
        <false/>
        <key>Summary</key>
        <string>This package enables testing of this previous version of iOS by installing legacy frameworks into the iOS Simulator.  If your app intends to support this version of iOS, it is highly recommended that you download this package to aid in your development and debugging.</string>
        <key>Xcode.SDKs</key>
        <array>
            <dict>
                <key>CanonicalName</key>
                <string>iphonesimulator5.0</string>
                <key>Path</key>
                <string>$(DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk</string>
                <key>Platform</key>
                <string>com.apple.platform.iphonesimulator</string>
                <key>SupportedDeviceFamilies</key>
                <array>
                    <integer>1</integer>
                    <integer>2</integer>
                </array>
                <key>Version</key>
                <string>5.0</string>
            </dict>
        </array>
    </dict>
    <key>version</key>
    <string>5.0.0.1</string>
</dict>
```

Lots of useful, readable information here. We see the 'displayed name' `Name` key, the `identifier` and `version`, the .dmg download at `source`, and some logic for how Xcode determines it's installed via `InstalledIfAllPathsArePresent`.

Notice the `RequiresADCAuthentication` key, which is fairly new. Previously these legacy Simulator downloads were hosted at `http://adcdownload.apple.com`, and would prompt you for an Apple ADC login. Currently there aren't any downloads that require an ADC login, so Apple's likely just reserving this behaviour for future use. It means it's easier for us to actually grab the .dmg without needing an auth cookie set by our browser, which used to require a manual download of Xcode in order to have it set.

The other very important piece here is the `InstallPrefix` key, set to `$(DEVELOPER)`. We're going to need this to actually install the .dmg correctly.

Once we've downloaded and mounted the installer .dmg, we can see it's just a .pkg installer. The installer is a flat package, and we can use the `pkgutil` to expand it to a working directory on our desktop and take a look:

```
pkgutil --expand /Volumes/MadRiver5M640.iPhoneSimulatorSDK5_0/iPhoneSimulatorSDK5_0.pkg ~/Desktop/simulator5
```

We've got the most basic flat package structure possible: a Bom, PackageInfo and Payload file. We can use the `lsbom` command to get a list of all the payload items. If we take a look at the first few items, we see the top few items in a folder hierarchy:

```
. 41775 0/80
./Platforms 40775 0/80
./Platforms/iPhoneSimulator.platform 40775 0/80
./Platforms/iPhoneSimulator.platform/Developer 40775 0/80
./Platforms/iPhoneSimulator.platform/Developer/SDKs 40775 0/80
./Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk 40775 0/80
```

Those './'s at the beginning look like relative paths, don't they? They are. If we'd install this package now using the `installer` command and specify a root OS volume like `/`, we'd wind up with this Platforms folder at the root of our drive, which is not what we want. If we dig around inside the Xcode app bundle, we can find where the more current iOS Simulator is stored, at:

```
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app
```

This correlates with the `InstallPrefix` key we saw earlier, telling us that we should effectively prefix this package's target location with folder with `/Applications/Xcode.app/Contents/Developer/`. To do this, we'll edit the `PackageInfo` file that contains metadata about the package. Specifically, we want to set the `install-location` attribute in the `pkg-info` element. See Stéphane Sudre's excellent [Flat Package Format](http://s.sudre.free.fr/Stuff/Ivanhoe/FLAT.html) page for more info on flat packages. With our small modification, the `PackageInfo` should now look something like this:

```xml
<pkg-info install-location="/Applications/Xcode.app/Contents/Developer" format-version="2" relocatable="true" deleteObsoleteLanguages="true" identifier="com.apple.pkg.iPhoneSimulatorSDK5_0" overwrite-permissions="no" auth="admin" postinstall-action="none" version="4.2.0.9000000000.1.1320101246">
```

Note the less-than-useful version number in the pkg itself. Now we can compile this back to a new flat package using the `--flatten` option for `pkgutil`:

```
pkgutil --flatten ~/Desktop/simulator5 ~/Desktop/iPhoneSimulatorSDK-5.0.0.1.pkg
```

The resulting file, `iPhoneSimulatorSDK-5.0.0.1.pkg`, should now be installable as an addition to your Xcode installation.

Unfortunately, we're still not done. If we skim through the index for this SDK's identifier, we come across another entry, that contains a `PatchFor` key:

```xml
<dict>
    <key>dependencies</key>
    <array/>
    <key>fileSize</key>
    <integer>409313</integer>
    <key>identifier</key>
    <string>Xcode.SDK.iPhoneSimulator.5.0</string>
    <key>name</key>
    <string>iOS 5.0 Simulator</string>
    <key>source</key>
    <string>http://devimages.apple.com/downloads/xcode/simulators/ios_50_simulator_patch1-3.dmg</string>
    <key>userInfo</key>
    <dict>
        <key>ApplicationsBlockingInstallation</key>
        <array>
            <string>com.apple.iphonesimulator</string>
        </array>
        <key>IconType</key>
        <string>IDEDownloadablesTypeSimulator</string>
        <key>InstallPrefix</key>
        <string>$(DEVELOPER)</string>
        <key>InstalledIfAllSHA1SumsMatch</key>
        <dict>
            <key>$(DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/System/Library/Frameworks/IOKit.framework/IOKit</key>
            <string>29cc63b14597d18b0ee72700e749e2094a6127a7</string>
            <key>$(DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/lib/libSystem.dylib</key>
            <string>ebba4cd3fd4b2efbb735fd03cf884f10868afe30</string>
            <key>$(DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/lib/libresolv.dylib</key>
            <string>7ef21e0bf165992bf10a5ff4d51deb56d5a212e3</string>
            <key>$(DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/lib/system/libSystem.override.dylib</key>
            <string>2fded02920f04513f5882e96fa9f643f0051f815</string>
            <key>$(DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/lib/system/libdispatch.dylib</key>
            <string>e810fc59fde1dabcb29d3377717be2a0a2f4e9a5</string>
            <key>$(DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/lib/system/libdispatch_debug.dylib</key>
            <string>9f04c46b5bdbb2c84c13413f7733c4cc78659049</string>
            <key>$(DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/lib/system/libdispatch_profile.dylib</key>
            <string>60e92f01a6821298740a24e4b8275cfe5120b9bf</string>
            <key>$(DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/lib/system/libxpc.dylib</key>
            <string>4313a977a95b9eab68e896e9fec3b1691beb0e9b</string>
            <key>$(DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/lib/system/libxpc_debug.dylib</key>
            <string>3d6bf9d76a3996c8b0fa1bb46dfce1d2f50dde91</string>
        </dict>
        <key>PatchFor</key>
        <array>
            <dict>
                <key>Identifier</key>
                <string>Xcode.SDK.iPhoneSimulator.5.0</string>
                <key>Version</key>
                <string>5.0.0.1</string>
            </dict>
        </array>
        <key>RequiresADCAuthentication</key>
        <false/>
        <key>Summary</key>
        <string>This package enables testing of this previous version of iOS by installing legacy frameworks into the iOS Simulator.  If your app intends to support this version of iOS, it is highly recommended that you download this package to aid in your development and debugging.</string>
        <key>Xcode.SDKs</key>
        <array>
            <dict>
                <key>CanonicalName</key>
                <string>iphonesimulator5.0</string>
                <key>Path</key>
                <string>$(DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk</string>
                <key>Platform</key>
                <string>com.apple.platform.iphonesimulator</string>
                <key>SupportedDeviceFamilies</key>
                <array>
                    <integer>1</integer>
                    <integer>2</integer>
                </array>
                <key>Version</key>
                <string>5.0</string>
            </dict>
        </array>
    </dict>
    <key>version</key>
    <string>5.0.1.1</string>
</dict>
```

Again, the logic is clear. It's a patch for version 5.0.0.1 of Xcode.SDK.iPhoneSimulator.5.0, and Xcode will know it's installed according to the contents of the `InstalledIfAllSHA1SumsMatch` key. In this case, it's the SHA-1 hashes of a bunch of library files. If you inspect the BOM of this patch installer, you'll see it's only installing the same patched libraries given in this `InstalledIfAllSHA1SumsMatch` dict. So, to install this you'll need to perform the same modification to the `PackageInfo` file to set the `install-location` attribute.

It's important to apply this patch, because if it is not applied, Xcode may detect that an installed component is not fully up to date, and prompt a dialog at launch, similar to when the MobileDevice support package is not installed or the correct version:

{{< imgcap
  img="/images/2012/11/xcode-legacy-simulator-update@2x.png"
>}}

A user can skip through this by failing the authorization prompt, but there's otherwise no option to simply bypass the update.

With that, we should have everything we need to deploy a specific legacy iOS Simulator/SDK version. We know where to get the installers, what version they are, how Xcode knows whether they're installed, and information for dependencies and patches that may see new uses in future versions. Your software distribution mechanism should be able to use all of this metadata to manage installations and updates for Xcode. If it doesn't, you may need to supplement it with some of your own checking mechanisms.

This post's specific use case of iOS Simulators may seem esoteric, but it's a good example of the index metadata Xcode uses for its supplemental downloads, and a practical use of the `pkgutil` command-line tool. With more and more packages being distributed in the flat package format, being familiar with using it to audit and modify packages is essential for administering OS X.
