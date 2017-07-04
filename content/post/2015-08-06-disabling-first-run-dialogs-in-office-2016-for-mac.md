---
date: 2015-08-06T21:03:56Z
slug: disabling-first-run-dialogs-in-office-2016-for-mac
tags:
- Office 2016
- preferences
title: Disabling First-run Dialogs in Office 2016 for Mac

wordpress_id: 1129
---

This post is part useful tidbit and part lesson in interacting with application preferences on OS X.

Office 2016 for Mac presents "first run" dialogs to the user to market some of its new features. Sysadmins often want to find ways to disable these for certain scenarios. I actually think these are often helpful for individual users, but may be less desirable on shared workstations or kiosk-like machines where users may use Office applications frequently from a "clean" profile that has never launched Office, and the repeated dialog becomes a nuisance.

{{< imgcap
    caption="Welcome dialog on first launch of Word 2016."
    img="/images/2015/08/msword2016_welcome.png"
>}}

There has been recent grumbling online about Microsoft's use of a registry-like format stored in an SQLite3 database for its user "registration" information, stored deep within a group container, and I've seen some assumptions that other preferences live here. While this might be the case, it seems like Office stores the "first-run" settings as standard OS X preferences within each application's preferences. They happen to be sandboxed apps, so they actually end up getting stored inside a given application's sandbox container. For example, Word:

`~/Library/Containers/com.microsoft.Word/Data/Library/Preferences/com.microsoft.Word.plist`

Mac sysadmins also tend to get hung up on plists and their paths, when it comes to preferences stored by the OS. Storage location and format of capital-P OS X Preferences, however, is an internal implementation detail that developers aren't really concerned with. Applications need not know or care where a preference actually gets stored, they simply ask the preferences system to handle reading and writing preferences. We should follow the model of the developers: use either the `defaults` or [CFPreferences](https://developer.apple.com/library/ios/documentation/CoreFoundation/Reference/CFPreferencesUtils/) methods provided by Apple (either from Python or C/Objective-C/Swift) to set this. Do _not_ use direct manipulation of plist files on disk to set preferences.

Knowing that there are some preferences stored in an app's container plist, notice how we can still "pick these up" by asking `defaults` for the prefs for the current user:

```
➜ ~  defaults read com.microsoft.Word

{
    AppExitGraceful = 1;
    ApplePersistenceIgnoreState = 1;
    NSRecentDocumentsLimit = 0;
    OCModelLanguage = "en-CA";
    OCModelVersion = "0.827";
    SendAllTelemetryEnabled = 1;
    SessionBuildNumber = 150724;
    SessionDuration = "4.805182993412018";
    SessionId = "9FBFC4A2-B0A5-4624-93C5-3811C77E4F1E";
    SessionStartTime = "08/06/2015 20:40:34.905";
    SessionVersion = "15.12.3";
    TemplateDownload = 1;
    WordInstallLanguage = 1033;
    kFileUIDefaultTabID = 1;
    kSubUIAppCompletedFirstRunSetup1507 = 1;
}
```

I've omitted many keys that existed on my machine from Word 2011 (which all start with `14`), but we can see there are several that are obviously for the latest version, given the `SessionVersion` value. The interesting one is `kSubUIAppCompletedFirstRunSetup1507`, a boolean.

We can test whether this will just work as a system-wide default by deleting our user's version and then setting it in the any-user "domain" (or "scope"):

```
➜ ~ defaults delete com.microsoft.Word kSubUIAppCompletedFirstRunSetup1507
➜ ~ sudo defaults write /Library/Preferences/com.microsoft.Word kSubUIAppCompletedFirstRunSetup1507 -bool true
```

Launch Word again to verify you're not getting a first-run dialog even though we deleted it from our user's preferences. Close Word, and verify that `kSubUIAppCompletedFirstRunSetup1507` was also _not set for the current user_ - the preferences system doesn't set a key for the user until the application requests setting it (possibly only if it would differ from that set in the any-user scope, which it didn't need to because the "first run" has already happened as far as Word is concerned.

Here are other application domains that seem to look for the same preference key (Outlook and OneNote seem to have their own additional "welcome" panes; see Outlook's `FirstRunExperienceCompletedO15`, for example):

```
com.microsoft.Outlook
com.microsoft.PowerPoint
com.microsoft.Excel
com.microsoft.Word
com.microsoft.onenote.mac
```
