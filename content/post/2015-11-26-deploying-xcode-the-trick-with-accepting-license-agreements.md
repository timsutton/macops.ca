---
author: tim
comments: true
date: 2015-11-26T20:44:54Z
slug: deploying-xcode-the-trick-with-accepting-license-agreements
tags:
- Xcode
title: Deploying Xcode - The Trick With Accepting License Agreements

wordpress_id: 1284
---

If you've ever gone through the process of automating Xcode installations, you've no doubt run across the issue of making sure that the license for Xcode and included SDKs has been accepted. An unlicensed Xcode looks like this on first launch, and asks for admin privileges:

{{< imgcap
    img="/images/2015/11/xcode-eula.png"
>}}

Or, try and run a command line utility and get:

```
➜  ~  strings


Agreeing to the Xcode/iOS license requires admin privileges, please re-run as root via sudo.
```


For a number of years the [Munki wiki](https://github.com/munki/munki/wiki) has been maintaining a list of actions to "finalize" an Xcode installation. See the script posted [here on the Munki wiki](https://github.com/munki/munki/wiki/Xcode#xcode-5), notably this part:

```
# accept Xcode license
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -license accept
```

This useful trick with `xcodebuild` works if you have only a single Xcode app to deploy, but the situation becomes less clear if you maintain several on a single machine. And, you may have seen from time to time that you install a different version of Xcode (or a Beta version) on your own machine, that you need to re-accept the license again. What exactly is going on here?

<!--more-->

The license "acceptance status" for Xcode is stored in a property list located in `/Library/Preferences/com.apple.dt.Xcode.plist`. This is not accessed with a preferences API, just reading and writing to a property list file. There are four keys that may store this license-related information. To see what I've got currently on my system, I'll print out the plist contents:

```
➜  ~  /usr/libexec/PlistBuddy -c 'Print' /Library/Preferences/com.apple.dt.Xcode.plist
Dict {
    IDEXcodeVersionForAgreedToGMLicense = 6.4
    IDEXcodeVersionForAgreedToBetaLicense = 7.2
    IDELastGMLicenseAgreedTo = EA1187
    IDELastBetaLicenseAgreedTo = EA1327
}
```

The fact that there are different keys for "GM" and "Beta" versions explains why accepting a license for a Beta version doesn't also cause the license to be accepted for a GM version, and vice versa.

I mentioned earlier the possibility of having multiple Xcode versions. This might be the case if you are developing or testing software that requires an older Xcode for compatibility with the project or included SDKs for older OS versions. You might name these Xcodes something like "Xcode-6.4.app", etc. so that you can keep multiple Xcodes side by side. The Ruby gem [XcodeInstall](https://github.com/neonichu/xcode-install), a tool for automating installation of multiple versions of Xcode, does this. (And as of recent releases you can also run this tool using 🎉 - yes, the Party Popper emoji, entered in your terminal prompt).

Having multiple Xcode versions means you'll have different versions of the agreement to accept. There are two important takeaways to know about this:

  1. When `xcodebuild -license accept` is run, it will apply the license agreement values to the plist according to the Xcode it's contained within.
  2. The keys like `IDELastGMLicenseAgreedTo` mean exactly that: they are the _last_ license agreed to, not the _newest_. For example, if you have Xcode 7.1 GM and Xcode 6.4 GM, and accept them in that order, Xcode 7.1 and its associated CLI tools will require accepting the license again, even though you already accepted the 7.1 license. However, accepting the newest license for either GM or Beta versions will include acceptance of licenses from previous versions. Therefore, if you have multiple GM or Beta Xcodes, the only way to guarantee they will all work is to accept only the latest of both GM and Beta versions you have installed.


If you want to know programatically what license values will be written to `com.apple.dt.Xcode.plist` when a license is accepted, you can do this by reading the contents of a file within the Xcode app bundle called `LicenseInfo.plist`:

```
➜  ~  /usr/libexec/PlistBuddy -c 'Print' Xcode-6.4.app/Contents/Resources/LicenseInfo.plist
Dict {
    licenseID = EA1187
    licenseType = GM
}
```

Looking at these values and the ones from the PlistBuddy command shown earlier, you can see how these are mapped. `licenseType` will be either `GM` or `Beta`, and these will determine which of the two pairs of keys in `com.apple.dt.Xcode.plist` will be set. The corresponding `XcodeVersionForAgreedTo..` key will contain Xcode.app's `CFBundleShortVersionString`.

Also, if you are ever curious about some of Xcode's support functions work surrounding the support packages, downloadables (simulators and docsets), etc. a good place to start looking is the `DVTFoundation` framework binary in `Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework`.
