---
title: Changes to Screen Sharing / Remote Desktop Management in macOS Monterey 12.1
date: 2021-12-17T10:45:44-04:00
description: Investigation into changes in macOS Monterey 12.1 for managing Screen Sharing / Remote Desktop
slug: managing-screen-sharing-in-monterey-12.1
tags:
  - remote-desktop
  - screen-sharing
  - macos-monterey
  - tcc
  - mdm
comments: false
---

During the beta cycle for macOS Monterey 12.1, a new change was added that's relevant for anyone administering macOS systems and using its built-in Screen Sharing / Remote Management service. Now that 12.1 is publicly available, it's the 2nd bullet entry in the [What's new for enterprise support document](https://support.apple.com/en-us/HT212586):

{{< imgcap
  img="/images/2021/12/12-1-relnotes.png"
>}}

I spent the last several days being confused by (1) how the change would impact my environment, (2) Apple's documentation, (3) mixed reports from others about whether their prior methods for enabling Screen Sharing / Remote Management were still working as usual for them on Monterey 12.1, and (4) disagreement over what components of their *existing* solutions were even required to have functional Screen Sharing. I came across multiple Slack threads where people were confused by Apple's documentation not matching their observations about existing solutions involving `kickstart` and PPPC configuration profiles.

The only macOS machines I manage are build servers used for continuous integration (CI), not for regular use, and so I am looking at this for this somewhat niche use-case. But, as I'm learning how to make use of MDM on headless build machines, what I dug up seems generally relevant for others leveraging Screen Sharing / Remote Desktop in their environments. So, this post is both a recap of what I've been able to make sense of and some ideas/research that I hope clarifies things going forward.

## Enabling prior to macOS 12.1

Prior to 12.1, it was possible to enable Screen Sharing by simply running this:

```bash
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
```

The additional set of "Remote Management" capabilities (used only when connecting to machines using [Apple Remote Desktop (ARD)](https://www.apple.com/remotedesktop/specs.html)) could be still enabled via the 2000-line Perl script that is [`kickstart`](https://ss64.com/osx/kickstart.html). A simple example of enabling Remote Management but restricting its use to the `admin` user (this all requires root):

```bash
kickstart=/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart
$kickstart -configure -allowAccessFor -specifiedUsers
$kickstart -configure -access -on -users admin -privs -all
$kickstart -activate
```

Confusingly, Apple did document that this would allow view-only as of macOS 10.14 Mojave, but this wasn't what I observed.

What I experience as of macOS 12.1 (and this seems _mostly_ echoed by others I talk with on the [MacAdmins Slack](https://www.macadmins.org/slack)) is that enabling Screen Sharing / Remote Management using either of the above methods leads to either a blank screen or a connection that just stalls forever, even though the target machine will display a popover from the menubar, with a message to the effect of "this screen is currently being observed."

The underlying cause for this behaviour change, is that the Screen Sharing service is now fully gated behind the [TCC mechanisms](https://eclecticlight.co/2018/10/10/watching-mojaves-privacy-protection-at-work/) in macOS. These prevent a service from (for example) recording a machine's screen without the user's explicit permission. Usually these show up in the [System Preference Privacy Pane](x-apple.systempreferences:com.apple.preference.security?Privacy), but Screen Sharing / Remote Management don't seem to show up in this list.

Apple's release notes point to [this support document](https://support.apple.com/en-us/HT209161), which at the time of writing states that if your target machine is enrolled in MDM, then it is possible to send an MDM command to enable Remote Desktop, and optionally a [PPPC payload](https://developer.apple.com/documentation/devicemanagement/privacypreferencespolicycontrol) configuration profile, granting `PostEvent` rights to the `com.apple.screensharing.agent` service, in order to allow control. In my experience, this is **incorrect**.

Sending _only_ the command, without any PPPC configuration profile, is sufficient to allow view and control.

Upon reading the [aforementioned KB](https://support.apple.com/en-us/HT209161) it took me some back and forth to understand that the actual command it is hinting at is `EnableRemoteDesktop`, as described in the [developer documentation](https://developer.apple.com/documentation/devicemanagement/enable_remote_desktop). That document also describes exactly what capabilities are enabled by the command, which match what I see from my experiments.

**Update, 2022-03-01:** Since originally publishing this article, it seems that the [above KB](https://support.apple.com/en-us/HT209161) has now been simplified (its last update as of today is January 26, 2022) to remove the details of to grant `PostEvent` permissions in a PPPC payload profile. The article now also explains the simplified (broad) scope of user permissions for Remote Desktop:

{{< imgcap
  img="/images/2022/03/revised-HT209161.png"
>}}


## Sending EnableRemoteDesktop from Workspace ONE UEM

The MDM I'm currently testing with is Workspace ONE UEM (a.k.a. AirWatch), which doesn't seem to support any special UI for sending this command, as some other MDMs seem to. However, there's a UI to send a "custom command" if one knows the expected command format as given by Apple. We can invoke a custom command on one or more selected devices via the "More Actions -> Custom Command" menu option in UEM like so:

{{< imgcap
  img="/images/2021/12/airwatch-custom-command.png"
>}}

The command [as documented](https://developer.apple.com/documentation/devicemanagement/enable_remote_desktop) is straightforward and has no parameters. The more obtuse part for me was knowing exactly how much of the plist/XML scaffolding the UEM UI expects, which is not documented and the UI's feedback is unhelpful. Some people in the [#workspaceone MacAdmins Slack channel](https://macadmins.slack.com/archives/C053TS6JT) helpfully showed me the way, that it must contain _only_ the dictionary of the request and any of its parameters (except in this case, this command has no parameters):

```xml
<dict>
	<key>RequestType</key>
	<string>EnableRemoteDesktop</string>
</dict>
```

Once this command is received and processed, one should immediately see the Sharing preference pane update to reflect the change, where the Remote Management service will show up as enabled. Control is also allowed for *all users* (more on that at the [end of this article]({{< relref "#security" >}})):

{{< imgcap
  img="/images/2021/12/sharing-after-mdm-enable.png"
>}}


It seems the other Apple-focused MDMs all support this command as a UI feature, and the API-driven open-source projects [microMDM](https://github.com/micromdm/micromdm/blob/5daf4d1c843f0f08d5f640785cccb1d5935005ca/mdm/mdm/marshal_proto.go#L47-L48) and [nanoMDM](https://github.com/micromdm/nanomdm/blob/fbe081c1c40c24de8f34a0afd43acf0b95145559/tools/cmdr.py#L145-L146) support this command as well.

## Confirming via TCC.db

The TCC sqlite3 databases continue to be (for nearly 10 years, [since OS X Mountain Lion]({{< relref "/post/2012-11-10-modifying-the-tcc-db.md" >}})) the source of truth for where privacy-related permissions are stored. We can look at these as one way to better understand what's going on when the `EnableRemoteDesktop` command is received and processed by a target machine. To clarify, this TCC db is _not_ the storage location for the specific Remote Desktop-related functions in the above screenshot – [*those* live in a bitmask](https://github.com/mosen/salt-osx/blob/990b6e7e2fd1965f943f396a350b409d38239d12/_modules/ard.py#L41-L70) stored in the directory's User records under the `naprivs` attribute. The TCC db is for permissions to access specific directories on disk, to allow processes to send Apple Events to other applications, automate usage of Accessibility functions of the OS, etc.

There's a TCC database at both `/Library` and `~/Library`, in this case we are just interested in the former. We also must [disable System Integrity Protection (SIP)](https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection) temporarily in order to gain access to this file, even for reading. Once that is done, and we have sent the `EnableRemoteDesktop` command via MDM, we can look at what rows have been added to the database:

```bash
sudo sqlite3 '/Library/Application Support/com.apple.TCC/TCC.db' .dump
```

The relevant entries are for `com.apple.screensharing.agent`, and we should expect to see these two:

```
 INSERT INTO access VALUES('kTCCServicePostEvent','com.apple.screensharing.agent',0,2,4,1,NULL,NULL,0,'UNUSED',NULL,0,1639743960);
 INSERT INTO access VALUES('kTCCServiceScreenCapture','com.apple.screensharing.agent',0,2,4,1,NULL,NULL,0,'UNUSED',NULL,0,1639743960);
```

A slightly nicer way to view just a few columns of interest is with the `box` output style and a query to just dump specific rows from the `access` table we're interested in:

```bash
$ sudo sqlite3 -box \
  '/Library/Application Support/com.apple.TCC/TCC.db' \
  "SELECT service, client, auth_value FROM access;"

┌─────────────────────────────────┬──────────────────────────────────┬────────────┐
│             service             │               client             │ auth_value │
├─────────────────────────────────┼──────────────────────────────────┼────────────┤
│ kTCCServiceDeveloperTool        │ com.apple.Terminal               │ 2          │
│ kTCCServiceSystemPolicyAllFiles │ com.apple.Terminal               │ 2          │
│ kTCCServiceSystemPolicyAllFiles │ com.charlessoft.pacifist         │ 0          │
│ kTCCServiceSystemPolicyAllFiles │ /usr/libexec/sshd-keygen-wrapper │ 2          │
│ kTCCServicePostEvent            │ com.apple.screensharing.agent    │ 2          │
│ kTCCServiceScreenCapture        │ com.apple.screensharing.agent    │ 2          │
└─────────────────────────────────┴──────────────────────────────────┴────────────┘
```
Among some other entries I have here, there's the `auth_value` of `2` (which is an 'allow') for the services needed for Screen Sharing to be useful for both observe and control.

We can also send the opposite command, `DisableRemoteDesktop`, and see these two entries have their `auth_value` flip back to `0`.

Since so far we haven't had anything to do with PPPC configuration profile payloads, it would appear that if we _only_ send the `EnableRemoteDesktop` command as we just did, we *don't* need to also allow `PostEvent` via a PPPC profile as Apple's KB suggests. If we had, then the MDM daemon on macOS would have landed those in `/Library/Application Support/com.apple.TCC/MDMOverrides.plist` and `tccd` would have accounted for those as well.

## Client status reporting

I figured that potentially an MDM may have access to the status of Remote Desktop for reporting purposes, even though UEM doesn't seem (at least not currently) to display this in anywhere in the details / status pane for a device alongside other security-related items like FileVault or System Integrity Protection statuses.

Hat tip to [Eric Holtam](https://twitter.com/eholtam) for teaching me this one, `mdmclient QuerySecurityInfo`:

```bash
$ sudo /usr/libexec/mdmclient QuerySecurityInfo
Daemon response: {
    SecurityInfo =     {
        AuthenticatedRootVolumeEnabled = 1;
        BootstrapTokenAllowedForAuthentication = "not supported";
        BootstrapTokenRequiredForKernelExtensionApproval = 0;
        BootstrapTokenRequiredForSoftwareUpdate = 0;
        "FDE_Enabled" = 1;

[...]

        RemoteDesktopEnabled = 1;

[...]
```

From what I can tell, `RemoteDesktopEnabled` status will be a boolean true (`1`) value even if the `com.apple.screensharing` service is simply running, regardless of whether necessary ScreenCapture / PostEvents permissions are allowed in the TCC database. So, this status output from `mdmclient QuerySecurityInfo` is not necessarily an indication that the `EnableRemoteDesktop` command had been sent and processed by the machine, merely that the system service is running at the time it was last queried.

## Use-case for build systems

Disabling SIP seems more commonplace for CI systems, for various reasons. If you manage CI systems, and don't yet have them enrolled in an MDM, but want to run Monterey 12.1 and can support SIP being disabled, then [this gist](https://gist.github.com/timsutton/31344ef60dbd4d64aca5b3287c0644e8) may help you.

A side-note on managing SIP, however, is that preserving a non-default SIP state on Apple Silicon is much more work than it was on Intel hardware. On Apple Silicon, SIP is [stored as part of the LocalPolicy file](https://support.apple.com/en-ca/guide/security/secc745a0845/web), which is paired to the OS installation and not simply persisted in NVRAM as it is on Intel.

Third-party Mac Mini colo providers (or baremetal/cloud hybrid solutions like [AWS EC2 Mac Instances](https://aws.amazon.com/ec2/instance-types/mac/), [MacStadium Orka](https://www.macstadium.com/orka), or [Flow Swiss's Mac Bare Metal](https://flow.swiss/mac-bare-metal)) provide varying degrees of additional support (in-person and with specialized proprietary hardware) for maintaining alternate SIP configurations. These types of machines may _also_ be problematic to enroll into MDM for a variety of reasons, so an approach of just manipulating the TCC.db file directly, as the above gist demonstrates, may still make more sense if you run build machines such as this with an external provider and have a use-case for screen sharing in software.

## Security

One concern I've seen others raise about this mechanism for enabling Remote Desktop, is that while the `kickstart` tool allows for specific ACLs around which users can access Remote Desktop and also what additional privileges they may have, upon sending the `EnableRemoteDesktop` MDM command, these ACL-type changes will be overwritten, requiring them to re-apply those again with a series of `kickstart` commands. Not all administrators necessarily want to allow screen control by all users. Sending MDM commands is its own task that is separate from executing administrative commands on a machine, and via two completely different mechanisms that would need to be orchestrated via the MDM and management tools (even if those two mechanisms live within the same product).

While I imagine it may be more convenient for admins if this screen sharing behaviour were possible to enable via a config profile, I think it is a better security posture for this to be something that is generally only enabled on an as-needed basis, at the time when remote access is required. However, I also could imagine that in certain environments like labs, that it's very convenient to have this setting be enabled automatically as part of some deployment/provisioning automation, and that now one may wish to look to customer-facing API automation that their MDM may support for making it easier to enable Screen Sharing either automatically or ad-hoc.

I'm also of the opinion that a change such as this – which is primarily of interest to enterprises, and introduces a breaking change in behaviour – doesn't belong in a `.1` release but should have been part of the summer beta cycle. [AppleSeed for IT](https://appleseed.apple.com/it) is one mechanism through which one can get more detailed, enterprise-focused release notes during beta cycles and a path to providing feedback to Apple for such issues.
