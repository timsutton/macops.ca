---
date: 2013-03-15T14:54:43Z
slug: managing-xcode-cli-tools
tags:
- deployment
- munki
- vendor metadata
- Xcode
title: Managing Xcode CLI tools
---

In a previous post on [deploying Xcode components]({{< relref "post/2012-11-19-xcode-deployment-the-dvtdownloadableindex-and-ios-simulators.md" >}}), I showed how the iOS Simulators are defined in a metadata file used by Apple, called `dvtdownloadableindex`, which is a binary plist containing information about all the "Components" available in the Downloads preference area.

What's useful about this file is that it describes in a human-readable way what Xcode uses to determine what component updates are available and what's already installed. Up until yesterday, the CLI tools used only SHA-1 sums on specific binaries and libraries to determine whether the package was installed, which was somewhat frustrating to those of us deploying it, because it meant the actual package receipt version numbers were next to useless. Munki, for example, couldn't use these to determine installed status, but one could at least use these to know what files to use to track the installation. Munki can use MD5 checksums to specify a file's contents.

Here's how they used to check their installed state:

```xml
<key>InstalledIfAllSHA1SumsMatch</key>
<dict>
    <key>/usr/bin/clang</key>
    <string>d8d5e4dcd2026aaeb5f98c691849fcde288b02db</string>
    <key>/usr/bin/lldb</key>
    <string>58a667d1bdeca37b46eebb7f307e6dc9ccc2a105</string>
    <key>/usr/lib/libSystem.B_debug.dylib</key>
    <string>451b59324546917f98b7b3a7e952408dfe4a6510</string>
</dict>
```

And here's the full entry for the latest version (4.5.9) of the CLI tools for Mountain Lion, released yesterday on March 14, 2013:

```xml
<dict>
    <key>dependencies</key>
    <array/>
    <key>fileSize</key>
    <integer>118401880</integer>
    <key>identifier</key>
    <string>Xcode.CLTools.10.8</string>
    <key>name</key>
    <string>Command Line Tools</string>
    <key>source</key>
    <string>http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_mountain_lion_march_2013.dmg</string>
    <key>userInfo</key>
    <dict>
        <key>ActivationPredicate</key>
        <string>$MAC_OS_X_VERSION >= '10.8.0' && $MAC_OS_X_VERSION < '10.9.0'</string>
       <key>InstallPrefix</key>
       <string>/</string>
       <key>InstalledIfAllReceiptsArePresentOrNewer</key>
       <dict>
           <key>com.apple.pkg.DevSDK</key>
           <string>10.8.0.0.1.1306847324</string>
           <key>com.apple.pkg.DeveloperToolsCLI</key>
           <string>4.6.0.0.1.1362189000</string>
       </dict>
       <key>RequiresADCAuthentication</key>
       <false/>
       <key>Summary</key>
       <string>Before installing, note that from within Terminal you can use the XCRUN tool to launch compilers and other tools embedded within the Xcode application. Use the XCODE-SELECT tool to define which version of Xcode is active.  Type "man xcrun" from within Terminal to find out more.

       Downloading this package will install copies of the core command line tools and system headers into system folders, including the LLVM compiler, linker, and build tools.</string>
       <key>Xcode.SDKs</key>
       <array/>
   </dict>
   <key>version</key>
   <string>4.5.9</string>
</dict>
```

Notice we have a download path, it doesn't require authentication to the Apple Developer Center (not long ago they did), and note in particular the `InstalledIfAllReceiptsArePresentOrNewer` key, with a dictionary of package receipts and versions. If I generate a new Munki pkginfo for this installer, my receipts array looks like this:

```xml
<key>receipts</key>
<array>
    <dict>
        <key>installed_size</key>
        <integer>238426</integer>
        <key>packageid</key>
        <string>com.apple.pkg.DevSDK</string>
        <key>version</key>
        <string>10.8.0.0.1.1306847324</string>
    </dict>
    <dict>
        <key>installed_size</key>
        <integer>253950</integer>
        <key>packageid</key>
        <string>com.apple.pkg.DeveloperToolsCLI</string>
        <key>version</key>
        <string>4.6.0.0.1.1362189000</string>
    </dict>
</array>
```

...which is much nicer than managing a bunch of file checksums. Hopefully they start using only receipts from now on.

