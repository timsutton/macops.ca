---
author: tim
comments: false
date: 2014-10-17T13:50:39Z
slug: yosemite-deployment-images-and-beta-feedback-assistant
tags:
  - Profiles
  - Setup Assistant
  - Yosemite
  - macos-deployment
title: Yosemite deployment images and (Beta) Feedback Assistant

wordpress_id: 756
---

<!-- [![fbasst_256x256](http://macops.ca/wp-content/uploads/2014/10/fbasst_256x256.png)](http://macops.ca/wp-content/uploads/2014/10/fbasst_256x256.png)
 -->
Yosemite was released yesterday, October 16, as OS X 10.10 build 14A389. One of the first thing a lot of Mac admins do with new OS releases is build never-booted disk images for deployment using the mighty [AutoDMG](https://github.com/MagerValp/AutoDMG) tool written by Per Olofsson.

While I still wait to see if Apple will offer my machine running the latest Yosemite Public Beta to upgrade to the exact same build number, I yesterday built an image of 14A389 on this system and added my usual handful of packages: creating an admin user, disabling the Setup Assistant and disabling the iCloud welcome dialog for new users.

In the past I've done this using a configuration profile based on one [posted by Greg Neagle](http://managingosx.wordpress.com/2012/07/26/mountain-lion-suppress-apple-id-icloud-prompt/), where I would modify the `LastSeenCloudProductVersion` key to contain later versions of the OS, in this case: `10.10`. Yesterday Rich Trouton also [helpfully posted](http://derflounder.wordpress.com/2014/10/16/disabling-the-icloud-and-diagnostics-pop-up-windows-in-yosemite/) an additional key that can be set in the `com.apple.SetupAssistant` preference domain, the `LastSeenBuddyBuildVersion` key, which allows us to bypass the prompt to submit diagnostics info to Apple and 3rd-party developers.

I have a package that installs this profile to `/private/var/db/ConfigurationProfiles/Setup` for an automated install on boot by OS X.

I added this new key to my profile and updated the build number to `14A389`, so my final profile has an `mcx_preference_settings` section that looks like this:

```xml
<key>mcx_preference_settings</key>
<dict>
    <key>DidSeeCloudSetup</key>
    <true/>
    <key>LastSeenCloudProductVersion</key>
    <string>10.10</string>
    <key>LastSeenBuddyBuildVersion</key>
    <string>14A389</string>
</dict>
```

The prompt in the Setup Assistant was suppressed as I expected. But, I was surprised to see the Feedback Assistant application launch automatically upon login.

{{< imgcap
    img="/images/2014/10/fbasst_screen.png"
>}}

After a couple of tests, I'm fairly sure this has been narrowed down to the fact that my image had been built on a Mac that was running using the Beta release. I'm not sure exactly what happened in the installer process, but possibly a script or some package metadata might have checked the component that launches the Feedback Assistant app and decided to enable it on the image I was building, even though the image being built was the final public release.

For those curious, this app gets launched by a LaunchAgent at `/System/Library/LaunchAgents/com.apple.appleseed.seedusaged.plist`, which triggers `/System/Library/CoreServices/Applications/Feedback Assistant.app/Contents/Library/LaunchServices/seedusaged`. Upon this first launch, the `com.apple.appleseed.FeedbackAssistant` preference domain gets a boolean key `Autolaunched` set to true. But it would seem from doing a couple of tests that this knowledge should hopefully be only academic, and that this problem can be avoided by simply building the 14A389 release on an 14A389 build machine.

Others have also chimed in and reported that they did not experience this issue when building on Developer Preview builds. The Feedback Assistant was made for Public Beta users, so this makes sense.
