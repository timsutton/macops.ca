---
date: 2013-08-16T13:45:10Z
slug: configuring-colorsync-display-profiles-using-the-command-line
tags:
- ColorSync
- PyObjC
- Python
title: Configuring ColorSync display profiles using the command-line

wordpress_id: 514
---

<!-- [![ColorSyncUtility_128.png](images/2013/08/ColorSyncUtility_128.png)](images/2013/08/ColorSyncUtility_128.png) -->

Managing ColorSync ICC profiles for displays is something I do for certain workstations via MCX, and it's always been a pain. Typically I would manually configure a profile for a display, then open up that user's ByHost .GlobalPreferences preference stored on disk, extract the keys for the hardware-specific GUID that corresponds to that monitor (something like `Device.mntr.00000610-0000-9C6B-0000-000004271AC0`), and import them into MCX, ending up with a blob like this:

```xml
<key>com.apple.ColorSync.Devices</key>
<dict>
    <key>Device.mntr.00000610-0000-9C6B-0000-000004271AC0</key>
    <dict>
        <key>CustomProfiles</key>
        <dict>
            <key>1</key>
            <string>/Library/ColorSync/Profiles/custom_profile_for_machine.icc</string>
        </dict>
    </dict>
</dict>
```

...which works, but I had to do a lot of manual work to get this configured, and I don't want to repeat this for 1) every machine needing a managed profile, and 2) every time a Mac or display gets changed. It would be nice if we could just specify a profile on the command line for a given display, and make it so.

Sure enough, there is a supported ColorSync API that can handle this, and the PyObjC Python-Objective-C bridge is there to help us implement it with little code, and no Xcode project or compilation required. I wrote a simple command-line utility that I've put up on GitHub [here](https://github.com/timsutton/customdisplayprofiles).

It turns out that this preference can also be configured at the "any-user" level, so this tool supports that. There's also a sample helper script in the GitHub repo that demonstrates how you could run this run this utility at login time for all users, such that these profiles can be managed easily by those calibrating the monitors.

<!-- TODO: add link to Greg's PyObjC post where he references this tool -->
