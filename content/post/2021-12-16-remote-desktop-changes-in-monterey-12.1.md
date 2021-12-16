---
title: Changes to Screen Sharing / Remote Desktop management in macOS Monterey 12.1
date: 2021-12-16T01:45:44-04:00
description: macOS Monterey 12.1 changes how administrators must manage Screen Sharing / Remote Desktop
slug: managing-screen-sharing-in-monterey-12.1
tags:
  - remote-desktop
  - screen-sharing
  - macos-monterey
  - tcc
  - mdm
comments: false
---

During the beta cycle for macOS Monterey 12.1, a new change was added that's relevant for anyone administering macOS systems and using Remote Desktop / Screen Sharing. Now that 12.1 is publicy available, it's the 2nd bullet entry in the [What's new for enterprise support document](https://support.apple.com/en-us/HT212586):

**TODO: highlight the bullet**

{{< imgcap
  img="/images/2021/12/12-1-relnotes.png"
>}}

Prior to 12.1, it was still possible to very simply enable Screen Sharing this way:

```bash
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
```

...and the more sophisticated set of "Remote Management" capabilities (used only when connecting to machines using [Apple Remote Desktop (ARD)](https://www.apple.com/remotedesktop/specs.html)) could be still enabled via the 2000-line Perl script that is `kickstart`, for example if you wanted to restrict access to specific users and for specific privileges:

```bash
kickstart=/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart
$kickstart -configure -allowAccessFor -specifiedUsers
$kickstart -configure -access -on -users myadminuser -privs -all
$kickstart -activate
```

What I experience as of 12.1 (and this seems _mostly_ echoed by others I talk with on the [MacAdmins Slack](https://www.macadmins.org/slack)) is that this may lead to either a blank screen or a connection

What I believe is the actual mechanism at play here is that the Screen Sharing agent's practical benefit is now fully gated behind the TCC protections in macOS, which prevent a service from (for example) recording a machine's screen without the user's explicit permission. Usually these show up in the [System Preference Privacy Pane](x-apple.systempreferences:com.apple.preference.security?Privacy), but as Screen Sharing / Remote


## How to send Remote Desktop from your MDM

Add Airwatch example


microMDM supports it: https://github.com/micromdm/micromdm/blob/5daf4d1c843f0f08d5f640785cccb1d5935005ca/mdm/mdm/marshal_proto.go#L47-L48

nanoMDM: https://github.com/micromdm/nanomdm/blob/fbe081c1c40c24de8f34a0afd43acf0b95145559/tools/cmdr.py#L145-L146



It's going to vary system-by-system. Consult your MDM documentation.

## Client does report back status

Hat tip to Eric Holtam for teaching me this one (I'm very new to MDM):

```bash
sudo /usr/libexec/mdmclient QuerySecurityInfo
```

...will show the status output. This seems like it will reflect the status of the service running.

TODO: see what happens if I just enable the service but don't actually have TCC access?


## Use-case for build systems

To briefly touch on 
In my current role the only macOS systems I administer are build systems for CI, where I have some additional flexibility. For example, there's no real "user" with sensitive or private information,

Disabling System Integrity Protection (SIP) seems more commonplace for CI systems, for various reasons. If you manage CI systems, and don't yet have an MDM implementation, but want to run Monterey 12.1 and can support SIP being disabled, then [this gist](https://gist.github.com/timsutton/31344ef60dbd4d64aca5b3287c0644e8) may help you. It inserts the necessary rights for `com.apple.screensharing.agent` into the [TCC database]({{< relref "/post/2012-11-10-modifying-the-tcc-db.md" >}}).

