---
comments: false
date: 2014-11-18T19:35:17Z
slug: diagnostics-prompt-yosemite
tags:
  - Diagnostics Submission
  - Setup Assistant
  - Yosemite
  - macos-deployment
title: More about suppressing diagnostics submissions popups in OS X Yosemite

wordpress_id: 801
---

With OS X Yosemite, Apple added an additional phase to the Setup Assistant: the offer to submit diagnostics info to Apple and third-party developers, which is displayed either as part of a initial setup or upon first login (similar to the [iCloud prompt](http://managingosx.wordpress.com/2012/07/26/mountain-lion-suppress-apple-id-icloud-prompt)).

{{< imgcap
	img="/images/2014/11/yosemite_diagnostics.png"
>}}

Those who administer OS X clients typically look to disable such prompts on managed machines, either to avoid annoying users in shared workstation environments or because the organization may not (or may) wish to provide diagnostics information to Apple and third-party developers.

[Rich Trouton](http://derflounder.wordpress.com/2014/10/16/disabling-the-icloud-and-diagnostics-pop-up-windows-in-yosemite) has documented what seemed to be an additional preference key that could be configured in the `com.apple.SetupAssistant` domain: `LastSeenBuddyBuildVersion`. However, with the release of OS X 10.10.1 on November 17, some admins reported seeing this dialog pop up again, and then that it might be possible to suppress by updating this new key with the updated build number of OS X 10.10.1, 14B25.

Furthermore, whether it would show up seemed it may depend on whether the user is an admin or not. If the user was not an admin, the setup assistant window would still show but would simply show the "Setting Up Your Mac.." animation that plays at the end of the setup assistant process.

{{< imgcap
	img="/images/2014/11/yosemite_setting_up.png"
>}}

Back when Yosemite was available only as developer previews, [Rich had already documented on the Apple dev forums](https://devforums.apple.com/message/1049838) a process that seemed to disable this diagnostics prompt. This involves writing additional keys to a file at `/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist`. In my testing, unchecking both checkboxes (Apple and app developers) for diagnostic submissions results in at least the following keys getting set in this plist:

```xml
<key>AutoSubmitVersion</key>
<integer>4</integer>
<key>AutoSubmit</key>
<false/>
<key>ThirdPartyDataSubmitVersion</key>
<integer>4</integer>
<key>ThirdPartyDataSubmit</key>
<false/>
```

I looked again at whether this was still something that comes into play given this most recent 10.10.1 update. Digging through the binary at `/System/Library/CoreServices/SubmitDiagInfo` seems to suggest it is, with logging messages like: `Diagnostic message history store was not writeable. Will not submit diagnostic messsages`,  `admin user was unable to write into diagnostic message history`, and methods that determine whether the authenticated user is an admin user. This all confirms that the service managing the diagnostic messages expects that admin users can write directly to this file (and indeed, systems I've seen all set this file to have read/write access for the `admin` group).

I've since performed tests deploying an new, unbooted 10.10.1 image that contains no `LastSeenBuddyBuildVersion` key in `com.apple.SetupAssistant`, where in previous Yosemite testing I'd been setting this key via a Configuration Profile.

So as far as I can tell, it may be enough to suppress this diagnostics prompt using only a `DiagnosticMessagesHistory.plist` file placed at `/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist`, containing the above four keys. I've tested deploying this file within an image (built with [AutoDMG](https://github.com/MagerValp/AutoDMG)) using a standard installer package with no scripts.

One could also apply these plist keys to a booted system (using [Munki](https://github.com/munki/munki), for example) using a script like the following. Note the lack of the "$3" variable, meaning this script would not apply to non-booted volumes if run within a postinstall script. This script actually leaves the defaults as suggested by Apple, so tweak as desired - the objective here is to set them to _something_ so that this phase of the Setup Assistant does not show.

{{< gist timsutton 075cdf349106ef1255ff >}}

I consider this all still speculative. Rich Trouton has (also today) [documented an alternate approach](http://derflounder.wordpress.com/2014/11/18/automatically-suppressing-the-icloud-and-diagnostics-pop-up-windows-with-casper) to suppressing this diagnostics dialog. My theory at this time of writing is that while perhaps updating the setting for `LastSeenBuddyBuildVersion` in the Setup Assistant prevents these additional screens from showing, it's not what is actually determining the behavior of the diagnostics reporting mechanism.
